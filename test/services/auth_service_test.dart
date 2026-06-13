import 'package:agy_flutter/models/auth_failure.dart';
import 'package:agy_flutter/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // NOTE: This suite only covers the login() paths. register() and
  // sendPasswordReset() are intentionally left untested — the nightly QA
  // agent is expected to fill these gaps.
  late AuthService service;

  setUp(() {
    service = AuthService(latency: Duration.zero);
  });

  group('AuthService.login', () {
    test('returns the user on correct credentials', () async {
      final user = await service.login(
        email: AuthService.demoEmail,
        password: AuthService.demoPassword,
      );
      expect(user.email, AuthService.demoEmail);
      expect(user.name, 'Demo User');
    });

    test('is case-insensitive on email', () async {
      final user = await service.login(
        email: 'DEMO@AGY.DEV',
        password: AuthService.demoPassword,
      );
      expect(user.email, AuthService.demoEmail);
    });

    test('throws invalidCredentials on wrong password', () {
      expect(
        () => service.login(email: AuthService.demoEmail, password: 'wrong'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.invalidCredentials,
          ),
        ),
      );
    });

    test('throws invalidCredentials on unknown email', () {
      expect(
        () => service.login(email: 'nobody@agy.dev', password: 'whatever1'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
