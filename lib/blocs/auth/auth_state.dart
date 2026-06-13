part of 'auth_bloc.dart';

enum AuthStatus { unauthenticated, loading, authenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, AppUser? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, user, error];
}
