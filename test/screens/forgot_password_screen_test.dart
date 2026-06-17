import 'package:agy_flutter/models/auth_failure.dart';
import 'package:agy_flutter/screens/forgot_password_screen.dart';
import 'package:agy_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late AuthService authService;

  setUp(() {
    authService = _MockAuthService();
  });

  Widget pumpForgotPasswordScreen({required AuthService authService}) {
    return RepositoryProvider.value(
      value: authService,
      child: MaterialApp(home: const ForgotPasswordScreen()),
    );
  }

  testWidgets('renders email field and submit button', (tester) async {
    await tester.pumpWidget(pumpForgotPasswordScreen(authService: authService));

    expect(find.byKey(const Key('forgot_email')), findsOneWidget);
    expect(find.byKey(const Key('forgot_submit')), findsOneWidget);
    expect(
      find.text(
        "Enter your email and we'll send you a link to reset your password.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows validation errors when email is empty or invalid', (
    tester,
  ) async {
    await tester.pumpWidget(pumpForgotPasswordScreen(authService: authService));

    // Submit empty email
    await tester.tap(find.byKey(const Key('forgot_submit')));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(
      find.byKey(const Key('forgot_email')),
      'invalid-email',
    );
    await tester.tap(find.byKey(const Key('forgot_submit')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('shows SnackBar error when forgot password request fails', (
    tester,
  ) async {
    when(
      () => authService.sendPasswordReset(email: any(named: 'email')),
    ).thenThrow(const AuthFailure.userNotFound());

    await tester.pumpWidget(pumpForgotPasswordScreen(authService: authService));

    await tester.enterText(
      find.byKey(const Key('forgot_email')),
      'unknown@example.com',
    );
    await tester.tap(find.byKey(const Key('forgot_submit')));
    await tester.pump(); // Submit
    await tester.pump(); // SnackBar response

    expect(find.text('No account found for that email.'), findsOneWidget);
  });

  testWidgets(
    'shows success view on success, and back to sign in pops screen',
    (tester) async {
      when(
        () => authService.sendPasswordReset(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      // Wrap in parent route to verify popped screen
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: authService,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  key: const Key('go_button'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text('Go to Forgot Password'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open Forgot Password screen
      await tester.tap(find.byKey(const Key('go_button')));
      await tester.pumpAndSettle();

      // Fill and submit email
      await tester.enterText(
        find.byKey(const Key('forgot_email')),
        'user@example.com',
      );
      await tester.tap(find.byKey(const Key('forgot_submit')));
      await tester.pump(); // Start submitting
      await tester
          .pumpAndSettle(); // Resolve request and switch to success view

      // Verify success view is shown
      expect(find.byKey(const Key('forgot_success')), findsOneWidget);
      expect(find.text('Check your inbox'), findsOneWidget);

      // Tap back to sign in button
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();

      // Verify forgot password screen popped
      expect(find.byKey(const Key('go_button')), findsOneWidget);
      expect(find.byKey(const Key('forgot_success')), findsNothing);

      verify(
        () => authService.sendPasswordReset(email: 'user@example.com'),
      ).called(1);
    },
  );
}
