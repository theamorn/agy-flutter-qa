/// Typed authentication failures thrown by [AuthService].
///
/// Using an exception with a stable [message] keeps the blocs decoupled from
/// the service implementation and makes failure paths easy to assert in tests.
enum AuthFailureCode { invalidCredentials, emailInUse, userNotFound, unknown }

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final AuthFailureCode code;
  final String message;

  const AuthFailure.invalidCredentials()
    : this(AuthFailureCode.invalidCredentials, 'Invalid email or password.');

  const AuthFailure.emailInUse()
    : this(
        AuthFailureCode.emailInUse,
        'An account already exists for that email.',
      );

  const AuthFailure.userNotFound()
    : this(AuthFailureCode.userNotFound, 'No account found for that email.');

  @override
  String toString() => 'AuthFailure(${code.name}): $message';
}
