part of 'register_bloc.dart';

enum RegisterStatus { initial, submitting, success, failure }

class RegisterState extends Equatable {
  const RegisterState({
    this.status = RegisterStatus.initial,
    this.user,
    this.error,
  });

  final RegisterStatus status;
  final AppUser? user;
  final String? error;

  RegisterState copyWith({
    RegisterStatus? status,
    AppUser? user,
    String? error,
  }) {
    return RegisterState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, user, error];
}
