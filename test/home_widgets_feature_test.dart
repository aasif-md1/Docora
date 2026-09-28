import 'package:docora/features/widgets/domain/models/docora_widget_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Docora Widgets Hub Models Tests', () {
    test('Available widgets list has at least 5 rich widgets with complete definitions', () {
      final widgets = DocoraWidgetModel.availableWidgets;
      expect(widgets.length, greaterThanOrEqualTo(5));

      for (final widget in widgets) {
        expect(widget.id.isNotEmpty, isTrue);
        expect(widget.name.isNotEmpty, isTrue);
        expect(widget.subtitle.isNotEmpty, isTrue);
        expect(widget.gridSize.isNotEmpty, isTrue);
        expect(widget.description.isNotEmpty, isTrue);
        expect(widget.targetRoute.isNotEmpty, isTrue);
        expect(widget.capabilities.length, greaterThanOrEqualTo(3));
      }
    });

    test('Includes Instant Scanner, Recent Reading, Power Tools, Vault, and Reading Streak widgets', () {
      final ids = DocoraWidgetModel.availableWidgets.map((w) => w.id).toSet();
      expect(ids.contains('quick_scanner'), isTrue);
      expect(ids.contains('recent_reading'), isTrue);
      expect(ids.contains('tools_hub'), isTrue);
      expect(ids.contains('private_vault'), isTrue);
      expect(ids.contains('reading_tracker'), isTrue);
      expect(ids.contains('audio_reader'), isTrue);
    });

    test('Each capability has non-empty title and description explaining what it does', () {
      for (final widget in DocoraWidgetModel.availableWidgets) {
        for (final cap in widget.capabilities) {
          expect(cap.title.isNotEmpty, isTrue);
          expect(cap.description.isNotEmpty, isTrue);
        }
      }
    });
  });
}
