import 'dart:convert';
import 'dart:io';
import 'package:docora/core/services/local_document_server.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

enum GanderViewerType {
  docx,
  prose,
  xlsx,
  pptx,
  markdown,
  text,
}

/// Offline WebView bridge that hosts Gander's native JS viewer engines:
/// docx-preview, JSZip, prose-doc, SheetJS, PPTXjs, and marked.
class GanderDocumentWebView extends StatefulWidget {
  const GanderDocumentWebView({
    required this.filePath,
    required this.isNightMode,
    this.viewerType,
    this.onPageChanged,
    this.onSearchMatchesChanged,
    this.onLoadingStateChanged,
    this.onError,
    super.key,
  });

  final String filePath;
  final bool isNightMode;
  final GanderViewerType? viewerType;
  final void Function(int currentPage, int totalPages)? onPageChanged;
  final void Function(int currentMatch, int totalMatches)? onSearchMatchesChanged;
  final void Function(bool isLoading)? onLoadingStateChanged;
  final void Function(String error)? onError;

  @override
  State<GanderDocumentWebView> createState() => GanderDocumentWebViewState();
}

class GanderDocumentWebViewState extends State<GanderDocumentWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  WebViewController? get controller => _controller;

  @override
  void initState() {
    super.initState();
    _initViewer();
  }

  @override
  void didUpdateWidget(covariant GanderDocumentWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isNightMode != widget.isNightMode) {
      setNightMode(widget.isNightMode);
    }
    if (oldWidget.filePath != widget.filePath) {
      _initViewer();
    }
  }

  Future<void> _initViewer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    widget.onLoadingStateChanged?.call(true);

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', widget.filePath);
      }

      await LocalDocumentServer.instance.start();
      LocalDocumentServer.instance.setActiveDocument(widget.filePath);

      if (!mounted) return;

      final resolvedType = widget.viewerType ?? _detectViewerType(widget.filePath);
      final htmlFile = _resolveHtmlFile(resolvedType);
      final ext = p.extension(widget.filePath).replaceAll('.', '').toLowerCase();
      final name = p.basename(widget.filePath);

      final url = Uri.parse(
        '${LocalDocumentServer.instance.baseUrl}/$htmlFile'
        '?name=${Uri.encodeComponent(name)}'
        '&ext=${Uri.encodeComponent(ext)}'
        '&night=${widget.isNightMode ? '1' : '0'}',
      );

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(
          widget.isNightMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        )
        ..addJavaScriptChannel(
          'DocoraBridge',
          onMessageReceived: _handleBridgeMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              if (mounted) {
                setState(() => _isLoading = true);
                widget.onLoadingStateChanged?.call(true);
              }
            },
            onPageFinished: (url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                widget.onLoadingStateChanged?.call(false);
                // Synchronize initial night mode state
                setNightMode(widget.isNightMode);
              }
            },
            onWebResourceError: (error) {
              LoggerService.warning('WebView resource error: ${error.description}');
            },
          ),
        )
        ..loadRequest(url);

      setState(() {
        _controller = controller;
      });
    } catch (e) {
      LoggerService.warning('Failed to initialize Gander Document WebView: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        widget.onError?.call(e.toString());
      }
    }
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    final text = message.message.trim();
    if (text.isEmpty) return;

    // Handle page notifications: "page 3 15"
    if (text.startsWith('page ')) {
      final parts = text.split(' ');
      if (parts.length >= 3) {
        final cur = int.tryParse(parts[1]) ?? 1;
        final total = int.tryParse(parts[2]) ?? 1;
        widget.onPageChanged?.call(cur, total);
        return;
      }
    }

    // Handle search match notifications: "1 8 1" -> match 1 of 8, done 1
    final searchParts = text.split(' ');
    if (searchParts.length == 3) {
      final cur = int.tryParse(searchParts[0]);
      final total = int.tryParse(searchParts[1]);
      if (cur != null && total != null) {
        widget.onSearchMatchesChanged?.call(cur, total);
        return;
      }
    }
  }

  // ── Public API Controls ───────────────────────────────────────────────────

  /// Search in document using Gander's find.js
  void search(String query) {
    if (_controller == null) return;
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    final escaped = jsonEncode(query);
    _controller!.runJavaScript(
      'if (window.vwHandleCommand) { window.vwHandleCommand("q" + $escaped); }',
    );
  }

  void searchNext() {
    _controller?.runJavaScript(
      'if (window.vwHandleCommand) { window.vwHandleCommand("n"); }',
    );
  }

  void searchPrev() {
    _controller?.runJavaScript(
      'if (window.vwHandleCommand) { window.vwHandleCommand("p"); }',
    );
  }

  void clearSearch() {
    _controller?.runJavaScript(
      'if (window.vwHandleCommand) { window.vwHandleCommand("c"); }',
    );
  }

  void goToPage(int pageNumber) {
    _controller?.runJavaScript(
      'if (window.vwPageCommand) { window.vwPageCommand("g$pageNumber"); }',
    );
  }

  void setNightMode(bool isNight) {
    final flag = isNight ? '1' : '0';
    _controller?.runJavaScript(
      'if (window.vwPageCommand) { window.vwPageCommand("i$flag"); }',
    );
  }

  // ── Internal Helpers ──────────────────────────────────────────────────────

  static GanderViewerType _detectViewerType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.docx':
      case '.docm':
      case '.dotx':
        return GanderViewerType.docx;
      case '.doc':
      case '.odt':
      case '.rtf':
        return GanderViewerType.prose;
      case '.xlsx':
      case '.xls':
      case '.csv':
      case '.ods':
        return GanderViewerType.xlsx;
      case '.pptx':
      case '.ppsx':
      case '.pptm':
        return GanderViewerType.pptx;
      case '.md':
      case '.markdown':
        return GanderViewerType.markdown;
      default:
        return GanderViewerType.text;
    }
  }

  static String _resolveHtmlFile(GanderViewerType type) {
    switch (type) {
      case GanderViewerType.docx:
        return 'docx.html';
      case GanderViewerType.prose:
        return 'prose.html';
      case GanderViewerType.xlsx:
        return 'xlsx.html';
      case GanderViewerType.pptx:
        return 'pptx.html';
      case GanderViewerType.markdown:
        return 'md.html';
      case GanderViewerType.text:
        return 'text.html';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              Text(
                'Could not render document',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _initViewer,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          Container(
            color: widget.isNightMode
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
      ],
    );
  }
}
