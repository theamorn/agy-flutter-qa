import 'dart:async';

import '../models/app_user.dart';
import '../models/auth_failure.dart';

/// In-memory authentication backend.
///
/// No network, no persistence — a [Map] of email -> account seeded with one
/// demo account. Every call simulates latency so loading states are visible in
/// the UI and exercised by tests. Throws [AuthFailure] on the unhappy paths.
///
/// Pass [latency] = `Duration.zero` in tests to keep them fast.
class AuthService {
  AuthService({this.latency = const Duration(milliseconds: 400)})
    : _accounts = {
        demoEmail: _Account(name: 'Demo User', password: demoPassword),
      };

  static const String demoEmail = 'demo@agy.dev';
  static const String demoPassword = 'password123';

  final Duration latency;
  final Map<String, _Account> _accounts;

  Future<void> _delay() => Future<void>.delayed(latency);

  /// Signs a user in. Throws [AuthFailure.invalidCredentials] on mismatch.
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    await _delay();
    final account = _accounts[_normalize(email)];
    if (account == null || account.password != password) {
      throw const AuthFailure.invalidCredentials();
    }
    return AppUser(email: _normalize(email), name: account.name);
  }

  /// Registers a new account. Throws [AuthFailure.emailInUse] if taken.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _delay();
    final key = _normalize(email);
    if (_accounts.containsKey(key)) {
      throw const AuthFailure.emailInUse();
    }
    _accounts[key] = _Account(name: name, password: password);
    return AppUser(email: key, name: name);
  }

  /// Sends a password-reset link. Throws [AuthFailure.userNotFound] if unknown.
  Future<void> sendPasswordReset({required String email}) async {
    await _delay();
    if (!_accounts.containsKey(_normalize(email))) {
      throw const AuthFailure.userNotFound();
    }
  }

  String _normalize(String email) => email.trim().toLowerCase();
}

class _Account {
  _Account({required this.name, required this.password});
  final String name;
  final String password;
}
