import 'dart:async';
import 'dart:io';
import 'package:docora/core/services/logger_service.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// High-performance, 100% offline local HTTP server.
/// Serves vendored Gander viewer engine assets and active documents
/// over localhost to isolated in-app WebViews without any network access.
class LocalDocumentServer {
  LocalDocumentServer._();
  static final LocalDocumentServer instance = LocalDocumentServer._();

  HttpServer? _server;
  int _port = 0;
  String? _activeFilePath;

  int get port => _port;
  String get baseUrl => 'http://127.0.0.1:$_port';
  bool get isRunning => _server != null;

  /// Starts the local server on loopback IPv4 with an ephemeral port.
  Future<int> start() async {
    if (_server != null) return _port;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      LoggerService.info('LocalDocumentServer started on $baseUrl');

      _server!.listen(
        _handleRequest,
        onError: (Object error, StackTrace stack) {
          LoggerService.warning('LocalDocumentServer error: $error');
        },
      );
      return _port;
    } catch (e) {
      LoggerService.warning('Failed to start LocalDocumentServer: $e');
      rethrow;
    }
  }

  /// Sets the currently viewed document path.
  void setActiveDocument(String filePath) {
    _activeFilePath = filePath;
  }

  /// Stops the local server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = 0;
    LoggerService.info('LocalDocumentServer stopped');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    try {
      final path = request.uri.path;

      // Handle document stream endpoint: /doc/file or /doc/file.<ext>
      if (path.startsWith('/doc/')) {
        await _serveActiveDocument(request, response);
        return;
      }

      // Handle viewer asset endpoints: /docx.html, /app.js, /lib/...
      await _serveViewerAsset(request, response, path);
    } catch (e) {
      LoggerService.warning('Error handling request ${request.uri}: $e');
      try {
        response.statusCode = HttpStatus.internalServerError;
        response.write('Internal Server Error');
        await response.close();
      } catch (_) {}
    }
  }

  Future<void> _serveActiveDocument(
    HttpRequest request,
    HttpResponse response,
  ) async {
    if (_activeFilePath == null) {
      response.statusCode = HttpStatus.notFound;
      response.write('No active document set');
      await response.close();
      return;
    }

    final file = File(_activeFilePath!);
    if (!file.existsSync()) {
      response.statusCode = HttpStatus.notFound;
      response.write('Document file not found: $_activeFilePath');
      await response.close();
      return;
    }

    final totalLength = file.lengthSync();
    final ext = p.extension(_activeFilePath!).toLowerCase();
    final mimeType = _resolveDocMimeType(ext);

    response.headers.contentType = ContentType.parse(mimeType);
    response.headers.add('Accept-Ranges', 'bytes');
    response.headers.add('Cache-Control', 'no-store, no-cache, must-revalidate');

    // Handle HTTP Range header for streaming large files
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.tryParse(parts[0]) ?? 0;
      final end = (parts.length > 1 && parts[1].isNotEmpty)
          ? int.tryParse(parts[1]) ?? (totalLength - 1)
          : (totalLength - 1);

      if (start >= totalLength || end >= totalLength || start > end) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.add('Content-Range', 'bytes */$totalLength');
        await response.close();
        return;
      }

      final contentLength = end - start + 1;
      response.statusCode = HttpStatus.partialContent;
      response.headers.add('Content-Range', 'bytes $start-$end/$totalLength');
      response.contentLength = contentLength;

      await response.addStream(file.openRead(start, end + 1));
      await response.close();
      return;
    }

    response.statusCode = HttpStatus.ok;
    response.contentLength = totalLength;
    await response.addStream(file.openRead());
    await response.close();
  }

  Future<void> _serveViewerAsset(
    HttpRequest request,
    HttpResponse response,
    String requestPath,
  ) async {
    var cleanPath = requestPath.startsWith('/')
        ? requestPath.substring(1)
        : requestPath;
    if (cleanPath.isEmpty) cleanPath = 'docx.html';

    // Disallow path traversal
    if (cleanPath.contains('..')) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }

    final assetKey = 'assets/viewer/$cleanPath';
    try {
      final byteData = await rootBundle.load(assetKey);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      final ext = p.extension(cleanPath).toLowerCase();
      final mimeType = _resolveAssetMimeType(ext);

      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.parse(mimeType);
      response.headers.add('Cache-Control', 'public, max-age=3600');
      response.contentLength = bytes.length;
      response.add(bytes);
      await response.close();
    } catch (_) {
      response.statusCode = HttpStatus.notFound;
      response.write('Asset not found: $assetKey');
      await response.close();
    }
  }

  String _resolveDocMimeType(String ext) {
    switch (ext) {
      case '.docx':
      case '.docm':
      case '.dotx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.doc':
        return 'application/msword';
      case '.odt':
        return 'application/vnd.oasis.opendocument.text';
      case '.rtf':
        return 'application/rtf';
      case '.xlsx':
      case '.xlsm':
      case '.xltx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.csv':
        return 'text/csv; charset=utf-8';
      case '.ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case '.pptx':
      case '.ppsx':
      case '.pptm':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pdf':
        return 'application/pdf';
      case '.epub':
        return 'application/epub+zip';
      case '.md':
      case '.markdown':
        return 'text/markdown; charset=utf-8';
      case '.txt':
        return 'text/plain; charset=utf-8';
      default:
        return lookupMimeType('file$ext') ?? 'application/octet-stream';
    }
  }

  String _resolveAssetMimeType(String ext) {
    switch (ext) {
      case '.html':
        return 'text/html; charset=utf-8';
      case '.js':
      case '.mjs':
        return 'application/javascript; charset=utf-8';
      case '.css':
        return 'text/css; charset=utf-8';
      case '.wasm':
        return 'application/wasm';
      case '.json':
        return 'application/json; charset=utf-8';
      case '.svg':
        return 'image/svg+xml';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      case '.ttf':
        return 'font/ttf';
      default:
        return 'application/octet-stream';
    }
  }
}

