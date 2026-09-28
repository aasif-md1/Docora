import 'package:docora/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('DocoraApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});

    await tester.pumpWidget(
      const ProviderScope(
        child: DocoraApp(),
      ),
    );

    // Allow splash timer to complete and navigate
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(DocoraApp), findsOneWidget);
  });
}
