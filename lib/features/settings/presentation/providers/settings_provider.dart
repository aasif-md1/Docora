import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── General Preferences ─────────────────────────────────────────────────────

final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('pref_language') ?? 'en';
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_language', code);
  }
}

final defaultSortProvider = StateNotifierProvider<DefaultSortNotifier, String>(
  (ref) => DefaultSortNotifier(),
);

class DefaultSortNotifier extends StateNotifier<String> {
  DefaultSortNotifier() : super('date_desc') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('pref_default_sort') ?? 'date_desc';
  }

  Future<void> setSort(String sort) async {
    state = sort;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_default_sort', sort);
  }
}

final defaultViewProvider = StateNotifierProvider<DefaultViewNotifier, String>(
  (ref) => DefaultViewNotifier(),
);

class DefaultViewNotifier extends StateNotifier<String> {
  DefaultViewNotifier() : super('list') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('pref_default_view') ?? 'list';
  }

  Future<void> setView(String view) async {
    state = view;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_default_view', view);
  }
}

final startupScreenProvider = StateNotifierProvider<StartupScreenNotifier, String>(
  (ref) => StartupScreenNotifier(),
);

class StartupScreenNotifier extends StateNotifier<String> {
  StartupScreenNotifier() : super('home') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('pref_startup_screen') ?? 'home';
  }

  Future<void> setStartup(String screen) async {
    state = screen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_startup_screen', screen);
  }
}

// ── Document Viewer Preferences ─────────────────────────────────────────────

final continuousScrollingProvider = StateNotifierProvider<BoolPrefNotifier, bool>(
  (ref) => BoolPrefNotifier('pref_continuous_scroll', defaultValue: true),
);

final rememberReadingPositionProvider = StateNotifierProvider<BoolPrefNotifier, bool>(
  (ref) => BoolPrefNotifier('pref_remember_position', defaultValue: true),
);

final keepScreenAwakeProvider = StateNotifierProvider<BoolPrefNotifier, bool>(
  (ref) => BoolPrefNotifier('pref_keep_awake', defaultValue: false),
);

final fullScreenModeProvider = StateNotifierProvider<BoolPrefNotifier, bool>(
  (ref) => BoolPrefNotifier('pref_fullscreen_mode', defaultValue: false),
);

// ── File Management Preferences ─────────────────────────────────────────────

final showHiddenFilesProvider = StateNotifierProvider<BoolPrefNotifier, bool>(
  (ref) => BoolPrefNotifier('pref_show_hidden', defaultValue: false),
);

final includeSubfoldersProvider = StateNotifierProvider<BoolPrefNotifier, bool>(
  (ref) => BoolPrefNotifier('pref_include_subfolders', defaultValue: true),
);

// ── Generic Bool Preference Notifier ────────────────────────────────────────

class BoolPrefNotifier extends StateNotifier<bool> {
  BoolPrefNotifier(this.key, {required this.defaultValue}) : super(defaultValue) {
    _load();
  }

  final String key;
  final bool defaultValue;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(key) ?? defaultValue;
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, next);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

// ── Cache & Storage Size Provider ───────────────────────────────────────────

final cacheSizeProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final cacheDir = await getTemporaryDirectory();
    if (!cacheDir.existsSync()) return 0;

    int total = 0;
    final files = cacheDir.listSync(recursive: true, followLinks: false);
    for (final f in files) {
      if (f is File) {
        total += f.lengthSync();
      }
    }
    return total;
  } catch (_) {
    return 0;
  }
});

