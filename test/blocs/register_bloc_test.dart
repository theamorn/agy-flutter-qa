import 'package:agy_flutter/blocs/register/register_bloc.dart';
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

  group('RegisterBloc', () {
    const name = 'New User';
    const email = 'newuser@example.com';
    const password = 'password123';
    const user = AppUser(email: email, name: name);

    blocTest<RegisterBloc, RegisterState>(
      'emits [submitting, success] when registration is successful',
      setUp: () {
        when(
          () => authService.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => user);
      },
      build: () => RegisterBloc(authService: authService),
      act: (bloc) => bloc.add(
        const RegisterSubmitted(name: name, email: email, password: password),
      ),
      expect: () => [
        const RegisterState(status: RegisterStatus.submitting),
        const RegisterState(status: RegisterStatus.success, user: user),
      ],
      verify: (_) {
        verify(
          () => authService.register(
            name: name,
            email: email,
            password: password,
          ),
        ).called(1);
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'emits [submitting, failure] when registration throws AuthFailure',
      setUp: () {
        when(
          () => authService.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthFailure.emailInUse());
      },
      build: () => RegisterBloc(authService: authService),
      act: (bloc) => bloc.add(
        const RegisterSubmitted(name: name, email: email, password: password),
      ),
      expect: () => [
        const RegisterState(status: RegisterStatus.submitting),
        const RegisterState(
          status: RegisterStatus.failure,
          error: 'An account already exists for that email.',
        ),
      ],
      verify: (_) {
        verify(
          () => authService.register(
            name: name,
            email: email,
            password: password,
          ),
        ).called(1);
      },
    );
  });

  group('RegisterEvent', () {
    test('supports value comparisons', () {
      expect(
        const RegisterSubmitted(
          name: 'name',
          email: 'email',
          password: 'password',
        ),
        equals(
          const RegisterSubmitted(
            name: 'name',
            email: 'email',
            password: 'password',
          ),
        ),
      );
    });
  });

  group('RegisterState', () {
    test('supports value comparisons', () {
      expect(const RegisterState(), equals(const RegisterState()));

      expect(
        const RegisterState().copyWith(status: RegisterStatus.submitting),
        equals(const RegisterState(status: RegisterStatus.submitting)),
      );

      const user = AppUser(email: 'a@b.com', name: 'Name');
      expect(
        const RegisterState(
          status: RegisterStatus.submitting,
          user: user,
          error: 'old error',
        ).copyWith(
          status: RegisterStatus.success,
          user: user,
          error: 'new error',
        ),
        equals(
          const RegisterState(
            status: RegisterStatus.success,
            user: user,
            error: 'new error',
          ),
        ),
      );
    });
  });
}
