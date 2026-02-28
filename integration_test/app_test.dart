import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskstack/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TaskStack integration tests', () {
    testWidgets('App starts on onboarding for fresh install', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        // Onboarding screen should be visible on first launch
        expect(find.text('The 24-Hour Stack'), findsOneWidget);
      });
    });

    testWidgets('Skipping onboarding goes to Stack screen', (tester) async {
      SharedPreferences.setMockInitialValues({'first_launch': false});
      await tester.runAsync(() async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        // Main stack screen
        expect(find.text('TaskStack'), findsAtLeast(1));
      });
    });
  });
}
