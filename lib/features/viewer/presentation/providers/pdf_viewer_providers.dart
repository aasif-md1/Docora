import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Active reading mode (Normal, Dark/Inverted, Sepia, Grayscale)
final pdfReadingModeProvider =
    StateProvider.autoDispose<PdfReadingMode>((ref) => PdfReadingMode.normal);

/// Active layout mode (Continuous Vertical vs Horizontal Single Page)
final pdfLayoutModeProvider =
    StateProvider.autoDispose<PdfLayoutMode>((ref) => PdfLayoutMode.verticalContinuous);

/// Keep screen awake / wakelock state
class WakelockNotifier extends StateNotifier<bool> {
  WakelockNotifier() : super(false);

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      await WakelockPlus.toggle(enable: next);
    } on Object catch (_) {
      // Wakelock might fail in test environments, handle gracefully
    }
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

final pdfWakelockProvider =
    StateNotifierProvider.autoDispose<WakelockNotifier, bool>((ref) {
  final notifier = WakelockNotifier();
  ref.onDispose(notifier.disable);
  return notifier;
});

/// Whether toolbar and overlays are hidden (fullscreen mode)
final pdfIsFullscreenProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Whether in-document text search bar is active
final pdfIsSearchingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Current active page number (1-based)
final pdfCurrentPageProvider =
    StateProvider.autoDispose<int>((ref) => 1);

/// Total page count of the active PDF
final pdfTotalPagesProvider =
    StateProvider.autoDispose<int>((ref) => 1);

/// Current zoom ratio of the active PDF
final pdfZoomRatioProvider =
    StateProvider.autoDispose<double>((ref) => 1.0);
