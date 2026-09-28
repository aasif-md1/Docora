package com.docora.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Environment
import android.os.StatFs
import android.widget.RemoteViews
import java.io.File
import java.util.Locale

open class BaseDocoraWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    open fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_DEFAULT"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val views = RemoteViews(context.packageName, R.layout.widget_scanner_layout)
        views.setOnClickPendingIntent(R.id.widget_scanner_root, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_action_scan, pendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

class DocoraScannerWidget : BaseDocoraWidgetProvider() {
    override fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_SCAN"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/scanner")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val views = RemoteViews(context.packageName, R.layout.widget_scanner_layout)
        views.setOnClickPendingIntent(R.id.widget_scanner_root, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_action_scan, pendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

class DocoraToolsWidget : BaseDocoraWidgetProvider() {
    override fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_tools_layout)

        // Root click -> /tools
        val intentRoot = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOLS_ROOT"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools")
        }
        val pendingRoot = PendingIntent.getActivity(
            context,
            appWidgetId * 10,
            intentRoot,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_tools_root, pendingRoot)

        // Tool 1: Image to PDF -> /tools/image-to-pdf
        val intentImgPdf = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOL_IMG_PDF"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools/image-to-pdf")
        }
        val pendingImgPdf = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 1,
            intentImgPdf,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.tool_action_img_pdf, pendingImgPdf)

        // Tool 2: Merge PDF -> /tools/merge
        val intentMerge = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOL_MERGE"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools/merge")
        }
        val pendingMerge = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 2,
            intentMerge,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.tool_action_merge, pendingMerge)

        // Tool 3: Watermark -> /tools/watermark
        val intentWatermark = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOL_WATERMARK"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools/watermark")
        }
        val pendingWatermark = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 3,
            intentWatermark,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.tool_action_watermark, pendingWatermark)

        // Tool 4: Compress -> /tools/compress
        val intentCompress = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOL_COMPRESS"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools/compress")
        }
        val pendingCompress = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 4,
            intentCompress,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.tool_action_compress, pendingCompress)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

class DocoraRecentWidget : BaseDocoraWidgetProvider() {
    override fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lastTitle = prefs.getString("flutter.widget_last_doc_title", null)
            ?: prefs.getString("flutter.last_opened_doc_title", null)
        val lastPath = prefs.getString("flutter.widget_last_doc_path", null)
            ?: prefs.getString("flutter.last_opened_doc_path", null)
        val lastProgress = prefs.getInt("flutter.widget_last_doc_progress", -1)

        val intent = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_RECENT"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!lastPath.isNullOrEmpty()) {
                putExtra("route", lastPath)
            } else {
                putExtra("route", "/files")
            }
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val views = RemoteViews(context.packageName, R.layout.widget_recent_layout)
        views.setOnClickPendingIntent(R.id.widget_recent_root, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_recent_button, pendingIntent)

        // Dynamic Document Title & Reading Progress
        if (!lastTitle.isNullOrEmpty()) {
            views.setTextViewText(R.id.widget_recent_title, lastTitle)
            val percent = if (lastProgress in 0..100) lastProgress else 0
            views.setTextViewText(R.id.widget_recent_progress_text, "$percent%")
            views.setProgressBar(R.id.widget_recent_progress_bar, 100, percent, false)
        } else {
            val recentDoc = findRecentDocumentOnDevice()
            if (recentDoc != null) {
                views.setTextViewText(R.id.widget_recent_title, recentDoc.name)
                views.setTextViewText(R.id.widget_recent_progress_text, "Ready")
                views.setProgressBar(R.id.widget_recent_progress_bar, 100, 10, false)
            } else {
                views.setTextViewText(R.id.widget_recent_title, "Resume Reading")
                views.setTextViewText(R.id.widget_recent_progress_text, "0%")
                views.setProgressBar(R.id.widget_recent_progress_bar, 100, 0, false)
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun findRecentDocumentOnDevice(): File? {
        val dirs = listOf(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
        )
        var newestFile: File? = null
        for (dir in dirs) {
            if (dir != null && dir.exists() && dir.isDirectory) {
                val files = dir.listFiles { f ->
                    f.isFile && (f.name.endsWith(".pdf", true) || f.name.endsWith(".docx", true) || f.name.endsWith(".pptx", true) || f.name.endsWith(".txt", true))
                } ?: continue
                for (f in files) {
                    if (newestFile == null || f.lastModified() > newestFile.lastModified()) {
                        newestFile = f
                    }
                }
            }
        }
        return newestFile
    }
}

class DocoraVaultWidget : BaseDocoraWidgetProvider() {
    override fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_VAULT"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/vault")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val views = RemoteViews(context.packageName, R.layout.widget_vault_layout)
        views.setOnClickPendingIntent(R.id.widget_vault_root, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_action_vault, pendingIntent)

        // REAL Dynamic Device Storage Calculation
        try {
            val stat = StatFs(Environment.getDataDirectory().path)
            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong
            val totalBytes = totalBlocks * blockSize
            val availableBytes = availableBlocks * blockSize
            val usedBytes = (totalBytes - availableBytes).coerceAtLeast(0L)

            val totalGB = String.format(Locale.US, "%.1f", totalBytes.toDouble() / (1024.0 * 1024.0 * 1024.0))
            val usedGB = String.format(Locale.US, "%.1f", usedBytes.toDouble() / (1024.0 * 1024.0 * 1024.0))
            val percent = if (totalBytes > 0) ((usedBytes * 100) / totalBytes).toInt().coerceIn(0, 100) else 0

            views.setTextViewText(R.id.widget_vault_storage_text, "$usedGB GB / $totalGB GB")
            views.setProgressBar(R.id.widget_vault_progress, 100, percent, false)
        } catch (e: Exception) {
            views.setTextViewText(R.id.widget_vault_storage_text, "Vault Protected")
            views.setProgressBar(R.id.widget_vault_progress, 100, 35, false)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

class DocoraReadingTrackerWidget : BaseDocoraWidgetProvider() {
    override fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TRACKER"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/home")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val views = RemoteViews(context.packageName, R.layout.widget_tracker_layout)
        views.setOnClickPendingIntent(R.id.widget_tracker_root, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_action_tracker, pendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

class DocoraAudioReaderWidget : BaseDocoraWidgetProvider() {
    override fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_AUDIO"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/home")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId * 10 + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val views = RemoteViews(context.packageName, R.layout.widget_audio_layout)
        views.setOnClickPendingIntent(R.id.widget_audio_root, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_action_audio_play, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_action_audio_prev, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_action_audio_next, pendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
