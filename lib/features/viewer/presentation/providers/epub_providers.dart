import 'package:docora/core/services/epub_parser_service.dart';
import 'package:docora/features/viewer/domain/models/epub_models.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Loads and parses an EPUB e-book publication.
final epubDocumentProvider =
    FutureProvider.autoDispose.family<EpubDocument, String>(
        (ref, filePath) => EpubParserService.parseFile(filePath));

/// Currently displayed chapter index (0-based).
final epubActiveChapterIndexProvider =
    StateProvider.autoDispose<int>((ref) => 0);

/// Font size for EPUB chapter reader (12.0 to 32.0, default 16.0).
final epubFontSizeProvider =
    StateProvider.autoDispose<double>((ref) => 16.0);

/// Reading / eye-comfort color theme (normal, dark, sepia).
final epubReadingModeProvider =
    StateProvider.autoDispose<PdfReadingMode>((ref) => PdfReadingMode.normal);

/// Screen wake-lock controller for long reading sessions.
class EpubWakelockNotifier extends StateNotifier<bool> {
  EpubWakelockNotifier() : super(false);

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      await WakelockPlus.toggle(enable: next);
    } on Object catch (_) {}
  }

  Future<void> disable() async {
    if (state) {
      state = false;
      try {
        await WakelockPlus.disable();
      } on Object catch (_) {}
    }
  }
}

final epubWakelockProvider =
    StateNotifierProvider.autoDispose<EpubWakelockNotifier, bool>((ref) {
  final notifier = EpubWakelockNotifier();
  ref.onDispose(notifier.disable);
  return notifier;
});
