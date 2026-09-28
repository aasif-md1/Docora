import 'package:docora/core/services/presentation_parser_service.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/domain/models/presentation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Loads and parses a PowerPoint (.pptx, .ppt) presentation deck.
final presentationDocumentProvider =
    FutureProvider.autoDispose.family<PresentationDocument, String>(
        (ref, filePath) => PresentationParserService.parseFile(filePath));

/// Active slide index (0-indexed).
final presentationActiveSlideProvider =
    StateProvider.autoDispose<int>((ref) => 0);

/// Fullscreen slideshow mode toggle.
final presentationFullscreenProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Auto-advance slideshow playing state.
final presentationAutoPlayProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Auto-advance interval in seconds.
final presentationAutoPlayIntervalProvider =
    StateProvider.autoDispose<int>((ref) => 5);

/// Speaker notes visibility toggle.
final presentationNotesVisibleProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// In-deck full-text search query.
final presentationSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Reading / eye-comfort color mode.
final presentationReadingModeProvider =
    StateProvider.autoDispose<PdfReadingMode>((ref) => PdfReadingMode.normal);

/// Presentation screen wake-lock controller.
class PresentationWakelockNotifier extends StateNotifier<bool> {
  PresentationWakelockNotifier() : super(false);

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

final presentationWakelockProvider =
    StateNotifierProvider.autoDispose<PresentationWakelockNotifier, bool>((ref) {
  final notifier = PresentationWakelockNotifier();
  ref.onDispose(notifier.disable);
  return notifier;
});
