import 'package:agy_flutter/blocs/auth/auth_bloc.dart';
import 'package:agy_flutter/models/app_user.dart';
import 'package:agy_flutter/models/auth_failure.dart';
import 'package:agy_flutter/services/auth_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late AuthService authService;

  setUp(() {
    authService = _MockAuthService();
  });

  // NOTE: Only the login flow is covered here. The AuthLogoutRequested
  // transition is intentionally left untested for the nightly QA agent.
  group('AuthBloc login', () {
    const user = AppUser(email: 'demo@agy.dev', name: 'Demo User');

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] on success',
      setUp: () {
        when(
          () => authService.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => user);
      },
      build: () => AuthBloc(authService: authService),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'demo@agy.dev',
          password: 'password123',
        ),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.authenticated, user: user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, failure] when the service throws',
      setUp: () {
        when(
          () => authService.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthFailure.invalidCredentials());
      },
      build: () => AuthBloc(authService: authService),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'demo@agy.dev', password: 'wrong'),
      ),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.failure,
          error: 'Invalid email or password.',
        ),
      ],
    );
  });
}
