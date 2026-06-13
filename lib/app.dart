import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';

/// Root widget. Provides the shared [AuthService] and [AuthBloc], then swaps
/// between the auth flow and the home shell based on session state.
class AgyApp extends StatelessWidget {
  const AgyApp({super.key, AuthService? authService})
    : _authService = authService;

  final AuthService? _authService;

  @override
  Widget build(BuildContext context) {
    final authService = _authService ?? AuthService();
    return RepositoryProvider.value(
      value: authService,
      child: BlocProvider(
        create: (_) => AuthBloc(authService: authService),
        child: MaterialApp(
          title: 'AGY',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          routes: {
            RegisterScreen.routeName: (_) => const RegisterScreen(),
            ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
          },
          home: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (a, b) => a.isAuthenticated != b.isAuthenticated,
            builder: (context, state) {
              return state.isAuthenticated
                  ? const HomeScreen()
                  : const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
