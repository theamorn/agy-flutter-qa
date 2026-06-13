import 'package:agy_flutter/app.dart';
import 'package:agy_flutter/screens/tabs/main_tab.dart';
import 'package:agy_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Use a zero-latency service so the flows run deterministically and fast.
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      AgyApp(authService: AuthService(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToRegister(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();
  }

  group('Register flow', () {
    testWidgets('successful registration lands on the home shell', (
      tester,
    ) async {
      await launch(tester);
      await goToRegister(tester);

      await tester.enterText(
        find.byKey(const Key('register_name')),
        'New User',
      );
      await tester.enterText(
        find.byKey(const Key('register_email')),
        'new.user@agy.dev',
      );
      await tester.enterText(
        find.byKey(const Key('register_password')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('register_submit')));
      await tester.pumpAndSettle();

      // We should be authenticated and on the main tab.
      expect(find.byType(MainTab), findsOneWidget);
      expect(find.text('Welcome, New User!'), findsOneWidget);
    });

    testWidgets('duplicate email shows an error and stays on register', (
      tester,
    ) async {
      await launch(tester);
      await goToRegister(tester);

      await tester.enterText(
        find.byKey(const Key('register_name')),
        'Demo User',
      );
      await tester.enterText(
        find.byKey(const Key('register_email')),
        AuthService.demoEmail,
      );
      await tester.enterText(
        find.byKey(const Key('register_password')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('register_submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('An account already exists for that email.'),
        findsOneWidget,
      );
      expect(find.byType(MainTab), findsNothing);
    });

    testWidgets('password mismatch blocks submission', (tester) async {
      await launch(tester);
      await goToRegister(tester);

      await tester.enterText(
        find.byKey(const Key('register_name')),
        'New User',
      );
      await tester.enterText(
        find.byKey(const Key('register_email')),
        'someone@agy.dev',
      );
      await tester.enterText(
        find.byKey(const Key('register_password')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm')),
        'different123',
      );

      await tester.tap(find.byKey(const Key('register_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(find.byType(MainTab), findsNothing);
    });
  });
}
