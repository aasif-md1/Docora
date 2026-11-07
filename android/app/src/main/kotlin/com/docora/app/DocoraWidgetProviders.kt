package com.docora.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Environment
import android.os.StatFs
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import androidx.core.graphics.ColorUtils
import androidx.core.graphics.drawable.DrawableCompat
import java.io.File
import java.util.Locale

object WidgetThemeHelper {
    // 16 curated accent colors matching AppColors.accentColorOptions
    val accentColors = intArrayOf(
        0xFF4F6BED.toInt(), // 0: Indigo Pulse
        0xFF2563EB.toInt(), // 1: Royal Cobalt
        0xFF0EA5E9.toInt(), // 2: Skyline Azure
        0xFF06B6D4.toInt(), // 3: Nordic Cyan
        0xFF0D9488.toInt(), // 4: Oceanic Teal
        0xFF10B981.toInt(), // 5: Mint Aurora
        0xFF16A34A.toInt(), // 6: Emerald Matrix
        0xFF84CC16.toInt(), // 7: Lime Volt
        0xFFEAB308.toInt(), // 8: Solar Flare
        0xFFD97706.toInt(), // 9: Sunset Amber
        0xFFF97316.toInt(), // 10: Coral Horizon
        0xFFC2410C.toInt(), // 11: Terracotta Rust
        0xFFE11D48.toInt(), // 12: Crimson Blaze
        0xFFEC4899.toInt(), // 13: Sakura Rose
        0xFF7C3AED.toInt(), // 14: Cyberpunk Violet
        0xFFA855F7.toInt()  // 15: Neon Amethyst
    )

    fun getAccentColor(context: Context): Int {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val all = prefs.all
            val raw = all["flutter.docora_accent_index"]
                ?: all["flutter.docora_accent_color_index"]
                ?: all["flutter.docora_accent_idx"]

            if (raw is Number) {
                val idx = raw.toInt()
                if (idx in 0 until accentColors.size) {
                    return accentColors[idx]
                }
            }

            val rawColor = all["flutter.widget_accent_color"]
            if (rawColor is Number) {
                val colorVal = rawColor.toInt()
                if (colorVal != 0) {
                    return colorVal
                }
            }
        } catch (_: Exception) {}
        return 0xFF4F6BED.toInt() // Fallback to brand default
    }

    fun isDarkMode(context: Context): Boolean {
        return try {
            val nightModeFlags = context.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
            nightModeFlags == android.content.res.Configuration.UI_MODE_NIGHT_YES
        } catch (_: Exception) {
            true
        }
    }
}

object WidgetBitmapHelper {
    fun getTintedIconBitmap(context: Context, drawableId: Int, tintColor: Int, sizeDp: Int = 22): Bitmap {
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val rawDrawable = ContextCompat.getDrawable(context, drawableId)?.mutate()
        if (rawDrawable != null) {
            val wrapped = DrawableCompat.wrap(rawDrawable)
            DrawableCompat.setTint(wrapped, tintColor)
            DrawableCompat.setTintMode(wrapped, PorterDuff.Mode.SRC_IN)
            wrapped.setBounds(0, 0, sizePx, sizePx)
            wrapped.draw(canvas)
        }
        return bitmap
    }

    fun getCircleButtonBitmap(context: Context, iconId: Int, bgColor: Int, sizeDp: Int = 44, iconDp: Int = 20): Bitmap {
        val density = context.resources.displayMetrics.density
        val px = (sizeDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = bgColor
            style = Paint.Style.FILL
        }
        canvas.drawCircle(px / 2f, px / 2f, px / 2f, paint)

        val rawDrawable = ContextCompat.getDrawable(context, iconId)?.mutate()
        if (rawDrawable != null) {
            val wrapped = DrawableCompat.wrap(rawDrawable)
            DrawableCompat.setTint(wrapped, Color.WHITE)
            val iconPx = (iconDp * density).toInt()
            val offset = (px - iconPx) / 2
            wrapped.setBounds(offset, offset, offset + iconPx, offset + iconPx)
            wrapped.draw(canvas)
        }
        return bitmap
    }

    fun getTintedCircleIconBitmap(context: Context, iconId: Int, accentColor: Int, sizeDp: Int = 40, iconDp: Int = 20): Bitmap {
        val density = context.resources.displayMetrics.density
        val px = (sizeDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ColorUtils.setAlphaComponent(accentColor, 45) // ~18% alpha container
            style = Paint.Style.FILL
        }
        canvas.drawCircle(px / 2f, px / 2f, px / 2f, paint)

        val rawDrawable = ContextCompat.getDrawable(context, iconId)?.mutate()
        if (rawDrawable != null) {
            val wrapped = DrawableCompat.wrap(rawDrawable)
            DrawableCompat.setTint(wrapped, accentColor)
            DrawableCompat.setTintMode(wrapped, PorterDuff.Mode.SRC_IN)
            val iconPx = (iconDp * density).toInt()
            val offset = (px - iconPx) / 2
            wrapped.setBounds(offset, offset, offset + iconPx, offset + iconPx)
            wrapped.draw(canvas)
        }
        return bitmap
    }

    fun getContinueButtonBitmap(context: Context, label: String, accentColor: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        val widthPx = (280 * density).toInt().coerceAtLeast(1)
        val heightPx = (40 * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val radius = 12 * density

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ColorUtils.setAlphaComponent(accentColor, 35) // ~14% alpha container
            style = Paint.Style.FILL
        }
        canvas.drawRoundRect(RectF(0f, 0f, widthPx.toFloat(), heightPx.toFloat()), radius, radius, bgPaint)

        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = accentColor
            textSize = 13 * density * 1.05f
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        }
        val yPos = (heightPx / 2f - (textPaint.descent() + textPaint.ascent()) / 2f)
        canvas.drawText(label, widthPx / 2f, yPos, textPaint)
        return bitmap
    }

    fun getProgressBarBitmap(context: Context, percent: Int, accentColor: Int, isDark: Boolean): Bitmap {
        val density = context.resources.displayMetrics.density
        val widthPx = (280 * density).toInt().coerceAtLeast(1)
        val heightPx = (6 * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val radius = heightPx / 2f

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isDark) Color.parseColor("#22252C") else Color.parseColor("#F2F4F7")
            style = Paint.Style.FILL
        }
        canvas.drawRoundRect(RectF(0f, 0f, widthPx.toFloat(), heightPx.toFloat()), radius, radius, trackPaint)

        val safePercent = percent.coerceIn(0, 100)
        if (safePercent > 0) {
            val fillWidth = (widthPx * (safePercent / 100f)).coerceAtLeast(heightPx.toFloat())
            val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = accentColor
                style = Paint.Style.FILL
            }
            canvas.drawRoundRect(RectF(0f, 0f, fillWidth, heightPx.toFloat()), radius, radius, fillPaint)
        }
        return bitmap
    }
}

object DocoraWidgetUpdater {
    fun updateAll(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context) ?: return
        val providers = listOf(
            DocoraScannerWidget(),
            DocoraToolsWidget(),
            DocoraVaultWidget(),
            DocoraReadingTrackerWidget()
        )
        for (provider in providers) {
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, provider::class.java))
            if (ids != null && ids.isNotEmpty()) {
                provider.onUpdate(context, appWidgetManager, ids)
            }
        }
    }
}

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

        // Dynamic Accent Styling from User Preference
        val accentColor = WidgetThemeHelper.getAccentColor(context)
        views.setImageViewBitmap(
            R.id.widget_scanner_left_icon,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_widget_camera, accentColor, 22)
        )
        views.setImageViewBitmap(
            R.id.widget_action_scan,
            WidgetBitmapHelper.getCircleButtonBitmap(context, R.drawable.ic_widget_camera, accentColor, 44, 20)
        )

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
        views.setOnClickPendingIntent(
            R.id.tool_action_img_pdf,
            PendingIntent.getActivity(context, appWidgetId * 10 + 1, intentImgPdf, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // Tool 2: Merge PDF -> /tools/merge
        val intentMerge = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOL_MERGE"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools/merge")
        }
        views.setOnClickPendingIntent(
            R.id.tool_action_merge,
            PendingIntent.getActivity(context, appWidgetId * 10 + 2, intentMerge, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // Tool 3: Watermark -> /tools/watermark
        val intentWatermark = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOL_WATERMARK"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools/watermark")
        }
        views.setOnClickPendingIntent(
            R.id.tool_action_watermark,
            PendingIntent.getActivity(context, appWidgetId * 10 + 3, intentWatermark, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // Tool 4: Compress -> /tools/compress
        val intentCompress = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TOOL_COMPRESS"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/tools/compress")
        }
        views.setOnClickPendingIntent(
            R.id.tool_action_compress,
            PendingIntent.getActivity(context, appWidgetId * 10 + 4, intentCompress, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // Dynamic Accent Styling for All 4 Tools
        val accentColor = WidgetThemeHelper.getAccentColor(context)
        views.setImageViewBitmap(
            R.id.tool_icon_img_pdf,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_widget_img_pdf, accentColor, 22)
        )
        views.setImageViewBitmap(
            R.id.tool_icon_merge,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_widget_merge, accentColor, 22)
        )
        views.setImageViewBitmap(
            R.id.tool_icon_watermark,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_widget_watermark, accentColor, 22)
        )
        views.setImageViewBitmap(
            R.id.tool_icon_compress,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_widget_compress, accentColor, 22)
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
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

        val accentColor = WidgetThemeHelper.getAccentColor(context)
        val isDark = WidgetThemeHelper.isDarkMode(context)

        // Top Lock Circle in exact user accent color
        views.setImageViewBitmap(
            R.id.widget_action_vault,
            WidgetBitmapHelper.getTintedCircleIconBitmap(context, R.drawable.ic_widget_lock, accentColor, 40, 20)
        )

        // Read real vault data from SharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val fileCount = try { prefs.getInt("flutter.widget_vault_count", -1) } catch (_: Exception) { -1 }
        val usedBytesPref = try { prefs.getInt("flutter.widget_vault_used_bytes", -1) } catch (_: Exception) { -1 }
        val totalBytesPref = try { prefs.getInt("flutter.widget_vault_total_bytes", -1) } catch (_: Exception) { -1 }

        if (fileCount > 0) {
            val fileText = if (fileCount == 1) "1 file secured" else "$fileCount files secured"
            views.setTextViewText(R.id.widget_vault_count_text, fileText)

            var percent = 0
            if (usedBytesPref >= 0 && totalBytesPref > 0) {
                val usedStr = formatBytes(usedBytesPref.toLong())
                val totalStr = formatBytes(totalBytesPref.toLong())
                percent = ((usedBytesPref.toFloat() / totalBytesPref) * 100).toInt().coerceIn(0, 100)
                views.setTextViewText(R.id.widget_vault_storage_text, "$usedStr of $totalStr")
            } else {
                // Calculate device storage as dynamic fallback
                try {
                    val stat = StatFs(Environment.getDataDirectory().path)
                    val blockSize = stat.blockSizeLong
                    val totalBytes = stat.blockCountLong * blockSize
                    val availableBytes = stat.availableBlocksLong * blockSize
                    val usedBytes = (totalBytes - availableBytes).coerceAtLeast(0L)
                    percent = if (totalBytes > 0) ((usedBytes * 100) / totalBytes).toInt().coerceIn(0, 100) else 0

                    views.setTextViewText(R.id.widget_vault_storage_text, "${formatBytes(usedBytes)} of ${formatBytes(totalBytes)}")
                } catch (_: Exception) {
                    views.setTextViewText(R.id.widget_vault_storage_text, "Encrypted vault")
                }
            }

            views.setImageViewBitmap(
                R.id.widget_vault_progress_image,
                WidgetBitmapHelper.getProgressBarBitmap(context, percent, accentColor, isDark)
            )
        } else {
            // Informative Default State (NEVER blank or empty!)
            views.setTextViewText(R.id.widget_vault_count_text, "Vault is empty")
            views.setTextViewText(R.id.widget_vault_storage_text, "Tap to lock & protect files")
            views.setImageViewBitmap(
                R.id.widget_vault_progress_image,
                WidgetBitmapHelper.getProgressBarBitmap(context, 0, accentColor, isDark)
            )
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun formatBytes(bytes: Long): String {
        if (bytes <= 0) return "0 B"
        val kb = bytes.toDouble() / 1024.0
        val mb = kb / 1024.0
        val gb = mb / 1024.0
        return when {
            gb >= 1.0 -> String.format(Locale.US, "%.1f GB", gb)
            mb >= 1.0 -> String.format(Locale.US, "%.1f MB", mb)
            kb >= 1.0 -> String.format(Locale.US, "%.1f KB", kb)
            else -> "$bytes B"
        }
    }
}

class DocoraReadingTrackerWidget : BaseDocoraWidgetProvider() {
    override fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_tracker_layout)

        // Root click -> /files
        val intentRoot = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_TRACKER"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/files")
        }
        val pendingRoot = PendingIntent.getActivity(
            context,
            appWidgetId * 10,
            intentRoot,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_tracker_root, pendingRoot)

        // PDF
        val intentPdf = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_OPEN_PDF"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/files")
            putExtra("filter", "pdf")
        }
        views.setOnClickPendingIntent(
            R.id.widget_tracker_pdf,
            PendingIntent.getActivity(context, appWidgetId * 10 + 1, intentPdf, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // Word
        val intentWord = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_OPEN_WORD"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/files")
            putExtra("filter", "word")
        }
        views.setOnClickPendingIntent(
            R.id.widget_tracker_word,
            PendingIntent.getActivity(context, appWidgetId * 10 + 2, intentWord, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // PPT
        val intentPpt = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_OPEN_PPT"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/files")
            putExtra("filter", "ppt")
        }
        views.setOnClickPendingIntent(
            R.id.widget_tracker_ppt,
            PendingIntent.getActivity(context, appWidgetId * 10 + 3, intentPpt, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // Excel
        val intentExcel = Intent(context, MainActivity::class.java).apply {
            action = "com.docora.app.ACTION_OPEN_EXCEL"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/files")
            putExtra("filter", "excel")
        }
        views.setOnClickPendingIntent(
            R.id.widget_tracker_excel,
            PendingIntent.getActivity(context, appWidgetId * 10 + 4, intentExcel, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        )

        // Dynamic Accent Styling for Quick Open format icons
        val accentColor = WidgetThemeHelper.getAccentColor(context)
        views.setImageViewBitmap(
            R.id.tracker_icon_pdf,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_format_pdf, accentColor, 22)
        )
        views.setImageViewBitmap(
            R.id.tracker_icon_word,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_format_word, accentColor, 22)
        )
        views.setImageViewBitmap(
            R.id.tracker_icon_ppt,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_format_ppt, accentColor, 22)
        )
        views.setImageViewBitmap(
            R.id.tracker_icon_excel,
            WidgetBitmapHelper.getTintedIconBitmap(context, R.drawable.ic_format_excel, accentColor, 22)
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
