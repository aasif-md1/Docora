import 'package:docora/core/services/docx_parser_service.dart';
import 'package:docora/features/viewer/domain/models/docx_models.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Loads and parses a DOCX or DOC document asynchronously.
final wordDocumentProvider =
    FutureProvider.autoDispose.family<DocxDocument, String>(
        (ref, filePath) => DocxParserService.parseFile(filePath));

/// Font scaling factor (0.8x to 2.0x) for text rendering.
final wordFontScaleProvider =
    StateProvider.autoDispose<double>((ref) => 1.0);

/// Visual reading mode (Normal, Dark, Sepia, Grayscale).
final wordReadingModeProvider =
    StateProvider.autoDispose<PdfReadingMode>((ref) => PdfReadingMode.normal);

/// Active in-document search query.
final wordSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Active match index in search results.
final wordMatchIndexProvider =
    StateProvider.autoDispose<int>((ref) => 0);

/// Total number of search matches found in document.
final wordTotalMatchesProvider =
    StateProvider.autoDispose<int>((ref) => 0);

/// Wakelock state for keeping screen awake.
class WordWakelockNotifier extends StateNotifier<bool> {
  WordWakelockNotifier() : super(false);

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

final wordWakelockProvider =
    StateNotifierProvider.autoDispose<WordWakelockNotifier, bool>((ref) {
  final notifier = WordWakelockNotifier();
  ref.onDispose(notifier.disable);
  return notifier;
});
