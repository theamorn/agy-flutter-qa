import 'package:agy_flutter/blocs/auth/auth_bloc.dart';
import 'package:agy_flutter/screens/login_screen.dart';
import 'package:agy_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Covers rendering + the empty-form validation guard only. The successful
  // sign-in / navigation path is intentionally left for the nightly QA agent.
  Widget pumpLogin() {
    final authService = AuthService(latency: Duration.zero);
    return RepositoryProvider.value(
      value: authService,
      child: BlocProvider(
        create: (_) => AuthBloc(authService: authService),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
  }

  testWidgets('renders email, password and sign-in button', (tester) async {
    await tester.pumpWidget(pumpLogin());

    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting empty form', (
    tester,
  ) async {
    await tester.pumpWidget(pumpLogin());

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });
}
