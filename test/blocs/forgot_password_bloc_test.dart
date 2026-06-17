import 'package:agy_flutter/blocs/forgot_password/forgot_password_bloc.dart';
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

  group('ForgotPasswordBloc', () {
    const email = 'user@example.com';

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [submitting, success] when password reset is successful',
      setUp: () {
        when(
          () => authService.sendPasswordReset(email: any(named: 'email')),
        ).thenAnswer((_) async {});
      },
      build: () => ForgotPasswordBloc(authService: authService),
      act: (bloc) => bloc.add(const ForgotPasswordSubmitted(email: email)),
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        const ForgotPasswordState(status: ForgotPasswordStatus.success),
      ],
      verify: (_) {
        verify(() => authService.sendPasswordReset(email: email)).called(1);
      },
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [submitting, failure] when service throws AuthFailure',
      setUp: () {
        when(
          () => authService.sendPasswordReset(email: any(named: 'email')),
        ).thenThrow(
          const AuthFailure(AuthFailureCode.unknown, 'Server is down'),
        );
      },
      build: () => ForgotPasswordBloc(authService: authService),
      act: (bloc) => bloc.add(const ForgotPasswordSubmitted(email: email)),
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        const ForgotPasswordState(
          status: ForgotPasswordStatus.failure,
          error: 'Server is down',
        ),
      ],
      verify: (_) {
        verify(() => authService.sendPasswordReset(email: email)).called(1);
      },
    );
  });

  group('ForgotPasswordEvent', () {
    test('supports value comparisons', () {
      expect(
        const ForgotPasswordSubmitted(email: 'user@example.com'),
        equals(const ForgotPasswordSubmitted(email: 'user@example.com')),
      );
    });
  });

  group('ForgotPasswordState', () {
    test('supports value comparisons', () {
      expect(const ForgotPasswordState(), equals(const ForgotPasswordState()));

      expect(
        const ForgotPasswordState().copyWith(
          status: ForgotPasswordStatus.submitting,
        ),
        equals(
          const ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        ),
      );

      expect(
        const ForgotPasswordState(
          status: ForgotPasswordStatus.submitting,
          error: 'old error',
        ).copyWith(status: ForgotPasswordStatus.failure, error: 'new error'),
        equals(
          const ForgotPasswordState(
            status: ForgotPasswordStatus.failure,
            error: 'new error',
          ),
        ),
      );
    });
  });
}
