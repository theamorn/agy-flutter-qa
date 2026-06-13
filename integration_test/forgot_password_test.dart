import 'package:agy_flutter/app.dart';
import 'package:agy_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      AgyApp(authService: AuthService(latency: Duration.zero)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToForgot(WidgetTester tester) async {
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
  }

  group('Forgot password flow', () {
    testWidgets('known email shows the confirmation screen', (tester) async {
      await launch(tester);
      await goToForgot(tester);

      await tester.enterText(
        find.byKey(const Key('forgot_email')),
        AuthService.demoEmail,
      );
      await tester.tap(find.byKey(const Key('forgot_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forgot_success')), findsOneWidget);
      expect(find.text('Check your inbox'), findsOneWidget);
    });

    testWidgets('unknown email surfaces an error', (tester) async {
      await launch(tester);
      await goToForgot(tester);

      await tester.enterText(
        find.byKey(const Key('forgot_email')),
        'nobody@agy.dev',
      );
      await tester.tap(find.byKey(const Key('forgot_submit')));
      await tester.pumpAndSettle();

      expect(find.text('No account found for that email.'), findsOneWidget);
      expect(find.byKey(const Key('forgot_success')), findsNothing);
    });

    testWidgets('invalid email is blocked by validation', (tester) async {
      await launch(tester);
      await goToForgot(tester);

      await tester.enterText(
        find.byKey(const Key('forgot_email')),
        'not-an-email',
      );
      await tester.tap(find.byKey(const Key('forgot_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.byKey(const Key('forgot_success')), findsNothing);
    });
  });
}
