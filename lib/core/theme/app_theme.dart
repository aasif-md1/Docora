import 'dart:async';
import 'package:docora/core/services/widget_sync.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'docora_theme_mode';
const String _kIsAmoledKey = 'docora_is_amoled';
const String _kAccentIndexKey = 'docora_accent_index';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemeModeKey);
      if (saved != null) {
        state = switch (saved) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, mode.name);
    } catch (_) {}
  }
}

class AmoledNotifier extends StateNotifier<bool> {
  AmoledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_kIsAmoledKey);
      if (saved != null) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsAmoledKey, next);
    } catch (_) {}
  }

  Future<void> setAmoled(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsAmoledKey, value);
    } catch (_) {}
  }
}

class AccentColorIndexNotifier extends StateNotifier<int> {
  AccentColorIndexNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kAccentIndexKey);
      if (saved != null && saved >= 0 && saved < AppColors.accentOptions.length) {
        state = saved;
        unawaited(WidgetSync.syncAccentColor(saved));
      } else {
        unawaited(WidgetSync.syncAccentColor(0));
      }
    } catch (_) {}
  }

  Future<void> setAccentIndex(int index) async {
    if (index >= 0 && index < AppColors.accentOptions.length) {
      state = index;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kAccentIndexKey, index);
        unawaited(WidgetSync.syncAccentColor(index));
      } catch (_) {}
    }
  }
}

/// Provider for the current ThemeMode (Light / Dark / AMOLED / System) with SharedPreferences persistence
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

/// Provider for whether AMOLED dark mode is active (pure black background) with SharedPreferences persistence
final isAmoledProvider =
    StateNotifierProvider<AmoledNotifier, bool>((ref) => AmoledNotifier());

/// Provider for the user-selected accent color index with SharedPreferences persistence
final accentColorIndexProvider =
    StateNotifierProvider<AccentColorIndexNotifier, int>(
        (ref) => AccentColorIndexNotifier());

/// Provides the resolved [AppTheme] based on current accent selection
final appThemeProvider = Provider<AppTheme>((ref) {
  final accentIndex = ref.watch(accentColorIndexProvider);
  final isAmoled = ref.watch(isAmoledProvider);
  return AppTheme(
    accent: AppColors.accentOptions[accentIndex.clamp(0, AppColors.accentOptions.length - 1)],
    isAmoled: isAmoled,
  );
});

/// Encapsulates both the light and dark [ThemeData] for Docora.
class AppTheme {
  AppTheme({required this.accent, required this.isAmoled});

  final Color accent;
  final bool isAmoled;

  // ── Typography ─────────────────────────────────────────────────────────────

  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -0.25),
        displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600), // Screen title: 24px Semibold
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // Section heading: 18px Semibold
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500), // Card title: 16px Medium
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.2),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400), // Body: 14px Regular
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400), // Secondary: 13px Regular
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), // Button: 14-16px Semibold
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400), // Caption: 12px Regular
      );

  // ── Light Theme ─────────────────────────────────────────────────────────────

  ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: 0.12),
      onPrimaryContainer: accent,
      secondary: accent,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.primaryText,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.disabled,
    ).copyWith(
      surfaceContainerHighest: AppColors.surfaceVariantLight,
    );

    return _buildThemeData(colorScheme, Brightness.light, AppColors.backgroundLight);
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────────

  ThemeData get dark {
    final surface = isAmoled ? AppColors.surfaceAmoled : AppColors.surfaceDark;
    final bg = isAmoled ? AppColors.backgroundAmoled : AppColors.backgroundDark;

    final colorScheme = ColorScheme.dark(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: 0.25),
      onPrimaryContainer: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: AppColors.primaryTextDark,
      error: AppColors.errorRedDark,
      onError: Colors.white,
      outline: AppColors.borderDark,
    ).copyWith(
      surfaceContainerHighest: isAmoled
          ? AppColors.surfaceVariantAmoled
          : AppColors.surfaceElevatedDark,
    );

    return _buildThemeData(colorScheme, Brightness.dark, bg);
  }

  // ── Shared Build Logic ──────────────────────────────────────────────────────

  ThemeData _buildThemeData(ColorScheme colorScheme, Brightness brightness, Color scaffoldBg) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: _textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
        fontFamilyFallback: const ['Inter', 'Roboto', 'sans-serif'],
      ),

      // App bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom navigation
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Cards — semi-transparent borders (Emil Kowalski: use shadows over solid borders)
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.xl * 2), // 48dp height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.xl * 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: BorderSide.none,
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),

      // Snack bar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 4,
      ),

      // Page transitions — smooth, 60fps, no jank
      pageTransitionsTheme: const PageTransitionsTheme(),

      splashFactory: InkRipple.splashFactory,
    );
  }
}
