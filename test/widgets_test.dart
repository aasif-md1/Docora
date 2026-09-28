import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleDoc = DocumentEntity(
    id: 1,
    path: '/path/test_sample.pdf',
    name: 'test_sample.pdf',
    extension: 'pdf',
    mimeType: 'application/pdf',
    sizeBytes: 2048576,
    lastModified: DateTime(2026, 3, 15, 10, 30),
    openCount: 5,
    isFavorite: false,
    isDeleted: false,
    tags: const ['Report'],
    category: 'pdf',
    pageCount: 10,
  );

  group('DocumentFormatBadge Tests', () {
    testWidgets('renders PDF badge with label and vector icon without emojis',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentFormatBadge(
              format: DocumentFormat.pdf,
              size: BadgeSize.large,
            ),
          ),
        ),
      );

      expect(find.text('PDF'), findsOneWidget);
      expect(find.byIcon(LucideIcons.file_text), findsOneWidget);
    });

    testWidgets('renders Word badge correctly from extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentFormatBadge.fromExtension('docx'),
          ),
        ),
      );

      expect(find.text('WORD'), findsOneWidget);
      expect(find.byIcon(LucideIcons.file_pen), findsOneWidget);
    });
  });

  group('DocoraButton Tests', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocoraButton(
              label: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('renders loading spinner when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocoraButton(
              label: 'Loading Button',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('DocoraCard Tests', () {
    testWidgets('renders content within card variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocoraCard(
              variant: DocoraCardVariant.outlined,
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });
  });

  group('DocoraEmptyState Tests', () {
    testWidgets('renders title, description and action button without emoji',
        (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocoraEmptyState(
              icon: LucideIcons.file_search,
              title: 'No Documents',
              description: 'Try adding some files to view here.',
              actionLabel: 'Add File',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Documents'), findsOneWidget);
      expect(find.text('Try adding some files to view here.'), findsOneWidget);
      expect(find.text('Add File'), findsOneWidget);

      await tester.tap(find.text('Add File'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });
  });

  group('DocoraSearchField Tests', () {
    testWidgets('allows typing and clearing text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocoraSearchField(
              controller: controller,
              hintText: 'Search...',
            ),
          ),
        ),
      );

      expect(find.text('Search...'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Docora Invoice');
      await tester.pump();
      expect(controller.text, 'Docora Invoice');

      // Clear button should be visible
      final clearBtn = find.byIcon(LucideIcons.x);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pump();
      expect(controller.text, isEmpty);
    });
  });

  group('DocumentListItem Tests', () {
    testWidgets('renders document details, size, and handles tap',
        (tester) async {
      var tapped = false;
      var favoriteToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentListItem(
              document: sampleDoc,
              readingProgress: 0.5,
              onTap: () => tapped = true,
              onFavoriteToggle: () => favoriteToggled = true,
            ),
          ),
        ),
      );

      expect(find.text('test_sample.pdf'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('2.0 MB'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      await tester.tap(find.text('test_sample.pdf'));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.star_outline_rounded));
      await tester.pump();
      expect(favoriteToggled, isTrue);
    });
  });

  group('FilterChipBar Tests', () {
    testWidgets('renders filter chips and emits selection', (tester) async {
      String selected = 'all';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipBar(
              selectedId: selected,
              onSelected: (id) => selected = id,
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);

      await tester.tap(find.text('PDF'));
      await tester.pump();
      expect(selected, 'pdf');
    });
  });

  group('DocoraBottomSheet Tests', () {
    testWidgets('renders bottom sheet modal with title and action tiles',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  DocoraBottomSheet.show<void>(
                    context: ctx,
                    title: 'Actions',
                    builder: (sheetCtx) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DocoraActionTile(
                          icon: LucideIcons.share_2,
                          title: 'Share File',
                          onTap: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Share File'), findsOneWidget);

      await tester.tap(find.text('Share File'));
      await tester.pumpAndSettle();
      expect(find.text('Actions'), findsNothing);
    });
  });
}
