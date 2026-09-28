package com.docora.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.util.zip.ZipFile

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "DocoraIntent"
        private const val METHOD_CHANNEL = "com.docora.app/file_intent"
        private const val EVENT_CHANNEL = "com.docora.app/file_intent_stream"
        private const val ROUTE_EVENT_CHANNEL = "com.docora.app/route_intent_stream"
    }

    private var initialFilePath: String? = null
    private var initialRoute: String? = null
    private var eventSink: EventChannel.EventSink? = null
    private var routeEventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            try {
                onBackInvokedDispatcher.registerOnBackInvokedCallback(
                    android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT
                ) {
                    Log.d(TAG, "onBackInvokedCallback triggered - forwarding popRoute to flutterEngine")
                    flutterEngine?.navigationChannel?.popRoute()
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not register onBackInvokedCallback: ${e.message}")
            }
        }
        intent?.let {
            it.flags = it.flags and Intent.FLAG_ACTIVITY_MULTIPLE_TASK.inv()
            it.flags = it.flags and Intent.FLAG_ACTIVITY_NEW_DOCUMENT.inv()
        }
        val path = handleIntent(intent)
        if (path != null) {
            initialFilePath = path
            Log.d(TAG, "onCreate cached initial file: $path")
        }
        val route = intent?.getStringExtra("route")
        if (route != null) {
            initialRoute = route
            Log.d(TAG, "onCreate cached initial route: $route")
        }
    }

    override fun onBackPressed() {
        Log.d(TAG, "onBackPressed called - forwarding popRoute to flutterEngine")
        flutterEngine?.navigationChannel?.popRoute()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // If not processed in onCreate, process launch intent
        if (initialFilePath == null) {
            initialFilePath = handleIntent(intent)
            Log.d(TAG, "configureFlutterEngine resolved initial file: $initialFilePath")
        }
        if (initialRoute == null) {
            initialRoute = intent?.getStringExtra("route")
            if (initialRoute != null) {
                Log.d(TAG, "configureFlutterEngine resolved initial route: $initialRoute")
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFile" -> {
                    val path = initialFilePath
                    initialFilePath = null // consume once
                    Log.d(TAG, "MethodChannel getInitialFile returning: $path")
                    result.success(path)
                }
                "getInitialRoute" -> {
                    val route = initialRoute
                    initialRoute = null // consume once
                    Log.d(TAG, "MethodChannel getInitialRoute returning: $route")
                    result.success(route)
                }
                "resolveContentUri" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr != null) {
                        try {
                            val uri = Uri.parse(uriStr)
                            val resolved = copyContentUriToCache(this, uri, null)
                            result.success(resolved)
                        } catch (e: Exception) {
                            Log.e(TAG, "resolveContentUri error", e)
                            result.error("RESOLVE_FAILED", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                    }
                }
                "pinWidget" -> {
                    val widgetId = call.argument<String>("widgetId")
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        try {
                            val appWidgetManager = getSystemService(android.appwidget.AppWidgetManager::class.java)
                            val providerClass = when (widgetId) {
                                "quick_scanner" -> DocoraScannerWidget::class.java
                                "tools_hub" -> DocoraToolsWidget::class.java
                                "private_vault" -> DocoraVaultWidget::class.java
                                "reading_tracker" -> DocoraReadingTrackerWidget::class.java
                                "audio_reader" -> DocoraAudioReaderWidget::class.java
                                else -> DocoraRecentWidget::class.java
                            }
                            val component = android.content.ComponentName(this, providerClass)
                            if (appWidgetManager != null && appWidgetManager.isRequestPinAppWidgetSupported) {
                                val pinned = appWidgetManager.requestPinAppWidget(component, null, null)
                                result.success(pinned)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "pinWidget error", e)
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d(TAG, "EventChannel onListen registered")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(TAG, "EventChannel onCancel")
                }
            }
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ROUTE_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    routeEventSink = events
                    Log.d(TAG, "RouteEventChannel onListen registered")
                }

                override fun onCancel(arguments: Any?) {
                    routeEventSink = null
                    Log.d(TAG, "RouteEventChannel onCancel")
                }
            }
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.flags = intent.flags and Intent.FLAG_ACTIVITY_MULTIPLE_TASK.inv()
        intent.flags = intent.flags and Intent.FLAG_ACTIVITY_NEW_DOCUMENT.inv()
        setIntent(intent)
        val path = handleIntent(intent)
        Log.d(TAG, "onNewIntent received file: $path, eventSink is ${if (eventSink != null) "active" else "null"}")
        if (path != null) {
            if (eventSink != null) {
                eventSink?.success(path)
            } else {
                initialFilePath = path
            }
        }
        val route = intent.getStringExtra("route")
        if (route != null) {
            Log.d(TAG, "onNewIntent received route: $route, routeEventSink is ${if (routeEventSink != null) "active" else "null"}")
            if (routeEventSink != null) {
                routeEventSink?.success(route)
            } else {
                initialRoute = route
            }
        }
    }

    private fun handleIntent(intent: Intent?): String? {
        if (intent == null) return null
        val action = intent.action
        val intentMime = intent.type
        Log.d(TAG, "handleIntent action=$action, type=$intentMime, data=${intent.data}")

        if (Intent.ACTION_VIEW == action || Intent.ACTION_EDIT == action) {
            var uri: Uri? = intent.data
            if (uri == null && intent.clipData != null && intent.clipData!!.itemCount > 0) {
                uri = intent.clipData!!.getItemAt(0).uri
            }
            if (uri != null) {
                return copyContentUriToCache(this, uri, intentMime)
            }
        } else if (Intent.ACTION_SEND == action) {
            var uri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)
            if (uri == null && intent.clipData != null && intent.clipData!!.itemCount > 0) {
                uri = intent.clipData!!.getItemAt(0).uri
            }
            if (uri != null) {
                return copyContentUriToCache(this, uri, intentMime)
            }
        }
        return null
    }

    private fun copyContentUriToCache(context: Context, uri: Uri, intentMimeType: String?): String? {
        return try {
            // Direct readable file:// check
            if ("file".equals(uri.scheme, ignoreCase = true)) {
                val rawPath = uri.path
                if (rawPath != null) {
                    val decodedPath = try { Uri.decode(rawPath) } catch (_: Exception) { rawPath }
                    val directFile = File(decodedPath)
                    if (directFile.exists() && directFile.canRead()) {
                        Log.d(TAG, "Direct file readable: ${directFile.absolutePath}")
                        return directFile.absolutePath
                    }
                }
            }

            var displayName: String? = null
            var mimeType: String? = null

            try {
                mimeType = context.contentResolver.getType(uri)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to getType for uri: $uri", e)
            }

            if (mimeType.isNullOrBlank() || mimeType == "application/octet-stream") {
                mimeType = intentMimeType
            }

            if ("content".equals(uri.scheme, ignoreCase = true)) {
                try {
                    context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                            if (nameIndex != -1) {
                                displayName = cursor.getString(nameIndex)
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "query for DISPLAY_NAME failed: ${e.message}")
                }
            }

            if (displayName.isNullOrBlank()) {
                val lastSegment = uri.lastPathSegment ?: "document"
                displayName = try { Uri.decode(lastSegment) } catch (_: Exception) { lastSegment }
            }

            // Detect extension from URI string if missing
            val lowerName = displayName?.lowercase() ?: ""
            if (!lowerName.contains(".") || lowerName.endsWith(".")) {
                val uriStr = uri.toString().lowercase()
                val extFromUri = when {
                    uriStr.contains(".pdf") -> ".pdf"
                    uriStr.contains(".docx") -> ".docx"
                    uriStr.contains(".doc") -> ".doc"
                    uriStr.contains(".xlsx") -> ".xlsx"
                    uriStr.contains(".xls") -> ".xls"
                    uriStr.contains(".csv") -> ".csv"
                    uriStr.contains(".pptx") -> ".pptx"
                    uriStr.contains(".ppt") -> ".ppt"
                    uriStr.contains(".md") || uriStr.contains("readme") -> ".md"
                    uriStr.contains(".txt") -> ".txt"
                    uriStr.contains(".epub") -> ".epub"
                    uriStr.contains(".zip") -> ".zip"
                    uriStr.contains(".jpg") || uriStr.contains(".jpeg") -> ".jpg"
                    uriStr.contains(".png") -> ".png"
                    uriStr.contains(".webp") -> ".webp"
                    else -> null
                }

                if (extFromUri != null) {
                    displayName = "$displayName$extFromUri"
                } else {
                    val ext = mapMimeToExtension(mimeType)
                    displayName = "$displayName$ext"
                }
            }

            // Sanitize invalid path characters while preserving unicode and spaces
            displayName = displayName!!.replace("[\\\\/:*?\"<>|]".toRegex(), "_").trim()
            if (displayName.isEmpty()) {
                displayName = "document_${System.currentTimeMillis()}"
            }

            val cacheDir = File(context.cacheDir, "opened_documents")
            if (!cacheDir.exists()) {
                cacheDir.mkdirs()
            }

            val targetFile = File(cacheDir, displayName)
            val inputStream: InputStream? = if ("file".equals(uri.scheme, ignoreCase = true)) {
                val f = uri.path?.let { File(try { Uri.decode(it) } catch (_: Exception) { it }) }
                if (f != null && f.exists() && f.canRead()) {
                    FileInputStream(f)
                } else {
                    try { context.contentResolver.openInputStream(uri) } catch (e: Exception) {
                        Log.e(TAG, "Error openInputStream for file uri: $uri", e)
                        null
                    }
                }
            } else {
                try {
                    context.contentResolver.openInputStream(uri)
                } catch (e: Exception) {
                    Log.e(TAG, "Error openInputStream for content uri: $uri", e)
                    null
                }
            }

            if (inputStream != null) {
                inputStream.use { input ->
                    FileOutputStream(targetFile).use { output ->
                        input.copyTo(output)
                    }
                }
            } else {
                Log.e(TAG, "InputStream was null for uri: $uri")
            }

            if (targetFile.exists() && targetFile.length() > 0) {
                // Verify/repair extension via magic bytes inspection
                val ext = targetFile.extension.lowercase()
                if (ext.isEmpty() || ext == "bin" || ext == "tmp") {
                    val detectedExt = detectExtensionFromHeader(targetFile, mimeType)
                    if (detectedExt != null) {
                        val fixedFile = File(cacheDir, "${targetFile.nameWithoutExtension}.$detectedExt")
                        if (fixedFile.exists()) {
                            fixedFile.delete()
                        }
                        if (targetFile.renameTo(fixedFile)) {
                            Log.d(TAG, "File magic bytes fixed extension to: ${fixedFile.absolutePath}")
                            return fixedFile.absolutePath
                        }
                    }
                }
                Log.d(TAG, "Successfully cached document at: ${targetFile.absolutePath} (${targetFile.length()} bytes)")
                targetFile.absolutePath
            } else {
                Log.e(TAG, "Target file does not exist or is empty")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception in copyContentUriToCache", e)
            null
        }
    }

    private fun mapMimeToExtension(mimeType: String?): String {
        return when (mimeType?.lowercase()) {
            "application/pdf", "application/x-pdf", "application/acrobat", "applications/vnd.pdf", "text/pdf" -> ".pdf"
            "text/markdown", "text/x-markdown" -> ".md"
            "text/plain" -> ".txt"
            "text/csv", "application/csv", "text/comma-separated-values" -> ".csv"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> ".docx"
            "application/msword" -> ".doc"
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" -> ".xlsx"
            "application/vnd.ms-excel" -> ".xls"
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" -> ".pptx"
            "application/vnd.ms-powerpoint" -> ".ppt"
            "application/epub+zip" -> ".epub"
            "image/jpeg" -> ".jpg"
            "image/png" -> ".png"
            "image/webp" -> ".webp"
            "image/gif" -> ".gif"
            "application/zip", "application/x-zip-compressed" -> ".zip"
            else -> ".bin"
        }
    }

    private fun detectExtensionFromHeader(file: File, mimeHint: String?): String? {
        return try {
            val header = ByteArray(32)
            val bytesRead = FileInputStream(file).use { it.read(header) }
            if (bytesRead < 4) return null

            // PDF: %PDF
            if (header[0] == 0x25.toByte() && header[1] == 0x50.toByte() &&
                header[2] == 0x44.toByte() && header[3] == 0x46.toByte()) {
                return "pdf"
            }

            // ZIP based (docx, xlsx, pptx, epub, zip)
            if (header[0] == 0x50.toByte() && header[1] == 0x4B.toByte() &&
                header[2] == 0x03.toByte() && header[3] == 0x04.toByte()) {
                try {
                    ZipFile(file).use { zip ->
                        if (zip.getEntry("word/document.xml") != null) return "docx"
                        if (zip.getEntry("xl/workbook.xml") != null) return "xlsx"
                        if (zip.getEntry("ppt/presentation.xml") != null) return "pptx"
                        if (zip.getEntry("mimetype") != null || zip.getEntry("META-INF/container.xml") != null) return "epub"
                    }
                } catch (_: Exception) {}
                
                val hint = mimeHint?.lowercase() ?: ""
                return when {
                    hint.contains("word") -> "docx"
                    hint.contains("excel") || hint.contains("sheet") -> "xlsx"
                    hint.contains("presentation") || hint.contains("powerpoint") -> "pptx"
                    hint.contains("epub") -> "epub"
                    else -> "zip"
                }
            }

            // OLE2 Compound Document (doc, xls, ppt)
            if (header[0] == 0xD0.toByte() && header[1] == 0xCF.toByte() &&
                header[2] == 0x11.toByte() && header[3] == 0xE0.toByte()) {
                val hint = mimeHint?.lowercase() ?: ""
                return when {
                    hint.contains("presentation") || hint.contains("powerpoint") -> "ppt"
                    hint.contains("excel") || hint.contains("sheet") -> "xls"
                    else -> "doc"
                }
            }

            // PNG: \x89PNG
            if (header[0] == 0x89.toByte() && header[1] == 0x50.toByte() &&
                header[2] == 0x44.toByte() && header[3] == 0x47.toByte()) {
                return "png"
            }

            // JPEG: \xFF\xD8\xFF
            if (header[0] == 0xFF.toByte() && header[1] == 0xD8.toByte() && header[2] == 0xFF.toByte()) {
                return "jpg"
            }

            // WebP: RIFF....WEBP
            if (header[0] == 'R'.code.toByte() && header[1] == 'I'.code.toByte() &&
                header[2] == 'F'.code.toByte() && header[3] == 'F'.code.toByte() &&
                bytesRead >= 12 &&
                header[8] == 'W'.code.toByte() && header[9] == 'E'.code.toByte() &&
                header[10] == 'B'.code.toByte() && header[11] == 'P'.code.toByte()) {
                return "webp"
            }

            // GIF: GIF8
            if (header[0] == 'G'.code.toByte() && header[1] == 'I'.code.toByte() &&
                header[2] == 'F'.code.toByte() && header[3] == '8'.code.toByte()) {
                return "gif"
            }

            null
        } catch (_: Exception) {
            null
        }
    }
}
