import 'package:docora/core/services/text_file_service.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Loads and decodes a plain text, markdown, or code document.
final textDocumentProvider =
    FutureProvider.autoDispose.family<TextDocument, String>(
        (ref, filePath) => TextFileService.readFile(filePath));

/// Code / text font size in points (10.0 to 28.0).
final textFontSizeProvider =
    StateProvider.autoDispose<double>((ref) => 14.0);

/// Line numbers gutter visibility toggle.
final textShowLineNumbersProvider =
    StateProvider.autoDispose<bool>((ref) => true);

/// Line wrapping toggle (if false, enables horizontal scrolling).
final textWrapLinesProvider =
    StateProvider.autoDispose<bool>((ref) => true);

/// Reading / eye-comfort color mode.
final textReadingModeProvider =
    StateProvider.autoDispose<PdfReadingMode>((ref) => PdfReadingMode.normal);

/// In-document text search query.
final textSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Screen wake-lock controller.
class TextWakelockNotifier extends StateNotifier<bool> {
  TextWakelockNotifier() : super(false);

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

final textWakelockProvider =
    StateNotifierProvider.autoDispose<TextWakelockNotifier, bool>((ref) {
  final notifier = TextWakelockNotifier();
  ref.onDispose(notifier.disable);
  return notifier;
});
