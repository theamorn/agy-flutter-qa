import 'package:agy_flutter/blocs/auth/auth_bloc.dart';
import 'package:agy_flutter/models/app_user.dart';
import 'package:agy_flutter/models/auth_failure.dart';
import 'package:agy_flutter/screens/register_screen.dart';
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

  Widget pumpRegisterScreen({required AuthService authService}) {
    return RepositoryProvider.value(
      value: authService,
      child: BlocProvider(
        create: (_) => AuthBloc(authService: authService),
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
  }

  testWidgets('renders all input fields and register button', (tester) async {
    await tester.pumpWidget(pumpRegisterScreen(authService: authService));

    expect(find.byKey(const Key('register_name')), findsOneWidget);
    expect(find.byKey(const Key('register_email')), findsOneWidget);
    expect(find.byKey(const Key('register_password')), findsOneWidget);
    expect(find.byKey(const Key('register_confirm')), findsOneWidget);
    expect(find.byKey(const Key('register_submit')), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty or invalid', (
    tester,
  ) async {
    await tester.pumpWidget(pumpRegisterScreen(authService: authService));

    // Tap submit on empty fields
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pump();

    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);

    // Mismatched password validation
    await tester.enterText(find.byKey(const Key('register_name')), 'Test User');
    await tester.enterText(
      find.byKey(const Key('register_email')),
      'test@example.com',
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
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('shows SnackBar error when registration fails', (tester) async {
    when(
      () => authService.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthFailure.emailInUse());

    await tester.pumpWidget(pumpRegisterScreen(authService: authService));

    await tester.enterText(find.byKey(const Key('register_name')), 'Test User');
    await tester.enterText(
      find.byKey(const Key('register_email')),
      'test@example.com',
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
    await tester.pump(); // Start submitting
    await tester.pump(); // Receive response and build SnackBar

    expect(
      find.text('An account already exists for that email.'),
      findsOneWidget,
    );
  });

  testWidgets('performs registration, signs in, and pops screen on success', (
    tester,
  ) async {
    const user = AppUser(email: 'test@example.com', name: 'Test User');

    when(
      () => authService.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);

    when(
      () => authService.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);

    // Wrap in a parent route to verify the screen pops
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: authService,
        child: BlocProvider(
          create: (_) => AuthBloc(authService: authService),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  key: const Key('go_button'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Go to Register'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Navigate to register screen
    await tester.tap(find.byKey(const Key('go_button')));
    await tester.pumpAndSettle();

    // Fill the form
    await tester.enterText(find.byKey(const Key('register_name')), 'Test User');
    await tester.enterText(
      find.byKey(const Key('register_email')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm')),
      'password123',
    );

    // Submit
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pump(); // Start submitting
    await tester
        .pumpAndSettle(); // Resolve registration and login async actions, settle navigation

    // The register screen is popped, so the go button is visible again
    expect(find.byKey(const Key('go_button')), findsOneWidget);
    expect(find.byKey(const Key('register_submit')), findsNothing);

    verify(
      () => authService.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      ),
    ).called(1);

    verify(
      () =>
          authService.login(email: 'test@example.com', password: 'password123'),
    ).called(1);
  });
}
