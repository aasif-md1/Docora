import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for syncing live app state to Android Home Screen widgets.
/// Uses SharedPreferences (read directly by Android AppWidgetProvider RemoteViews).
class WidgetSync {
  WidgetSync._();

  static Timer? _debounceTimer;
  static const MethodChannel _channel = MethodChannel('com.docora.app/file_intent');

  /// Requests the native Android widget manager to re-render all active widgets immediately.
  static Future<void> triggerWidgetRefresh() async {
    try {
      await _channel.invokeMethod('updateAllWidgets');
    } catch (_) {}
  }

  // ── Accent Color Sync ──────────────────────────────────────────────────────

  /// Syncs user-selected accent color index so widgets dynamically match the app theme.
  static Future<void> syncAccentColor(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('docora_accent_index', index);
      await prefs.setInt('docora_accent_color_index', index);
      const colors = [
        0xFF4F6BED, // 0: Indigo Pulse
        0xFF2563EB, // 1: Royal Cobalt
        0xFF0EA5E9, // 2: Skyline Azure
        0xFF06B6D4, // 3: Nordic Cyan
        0xFF0D9488, // 4: Oceanic Teal
        0xFF10B981, // 5: Mint Aurora
        0xFF16A34A, // 6: Emerald Matrix
        0xFF84CC16, // 7: Lime Volt
        0xFFEAB308, // 8: Solar Flare
        0xFFD97706, // 9: Sunset Amber
        0xFFF97316, // 10: Coral Horizon
        0xFFC2410C, // 11: Terracotta Rust
        0xFFE11D48, // 12: Crimson Blaze
        0xFFEC4899, // 13: Sakura Rose
        0xFF7C3AED, // 14: Cyberpunk Violet
        0xFFA855F7, // 15: Neon Amethyst
      ];
      final safeIndex = index.clamp(0, colors.length - 1);
      await prefs.setInt('widget_accent_color', colors[safeIndex]);
      await triggerWidgetRefresh();
    } catch (_) {}
  }

  // ── Reading Progress Sync ──────────────────────────────────────────────────

  /// Updates the Resume Reading widget with the currently opened document and reading position.
  /// Debounced to avoid excessive writes during rapid scrolling or page turns.
  static void syncReadingProgress({
    required String filePath,
    required String fileName,
    required int currentPage,
    required int totalPages,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final safeTotal = totalPages > 0 ? totalPages : 1;
        final safePage = currentPage.clamp(1, safeTotal);
        final percent = ((safePage / safeTotal) * 100).round().clamp(0, 100);

        await prefs.setString('widget_last_doc_path', filePath);
        await prefs.setString('widget_last_doc_title', fileName);
        await prefs.setInt('widget_last_doc_page', safePage);
        await prefs.setInt('widget_last_doc_total_pages', safeTotal);
        await prefs.setInt('widget_last_doc_progress', percent);

        unawaited(triggerWidgetRefresh());
      } catch (_) {}
    });
  }

  /// Clears reading progress when history is cleared or file is deleted.
  static Future<void> clearRecentDoc() async {
    _debounceTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('widget_last_doc_path');
      await prefs.remove('widget_last_doc_title');
      await prefs.remove('widget_last_doc_page');
      await prefs.remove('widget_last_doc_total_pages');
      await prefs.remove('widget_last_doc_progress');
      await triggerWidgetRefresh();
    } catch (_) {}
  }

  // ── Vault Sync ─────────────────────────────────────────────────────────────

  /// Updates the Secure Vault widget with real encrypted file count and storage bytes.
  static Future<void> syncVaultState({
    required int fileCount,
    required int usedBytes,
    required int totalBytes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('widget_vault_count', fileCount);
      await prefs.setInt('widget_vault_used_bytes', usedBytes);
      await prefs.setInt('widget_vault_total_bytes', totalBytes);
      await triggerWidgetRefresh();
    } catch (_) {}
  }

  // ── Audio Reader / TTS Sync ────────────────────────────────────────────────

  /// Updates the Audio Reader widget with the active reading track and playback state.
  static Future<void> syncTtsState({
    required String fileName,
    required bool isPlaying,
    required double progress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_tts_title', fileName);
      await prefs.setBool('widget_tts_playing', isPlaying);
      await prefs.setInt('widget_tts_progress', (progress * 100).round().clamp(0, 100));
      await triggerWidgetRefresh();
    } catch (_) {}
  }

  /// Clears TTS state when audio stops or is dismissed.
  static Future<void> resetTtsState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('widget_tts_title');
      await prefs.setBool('widget_tts_playing', false);
      await prefs.setInt('widget_tts_progress', 0);
      await triggerWidgetRefresh();
    } catch (_) {}
  }
}
