part of 'forgot_password_bloc.dart';

enum ForgotPasswordStatus { initial, submitting, success, failure }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.error,
  });

  final ForgotPasswordStatus status;
  final String? error;

  ForgotPasswordState copyWith({ForgotPasswordStatus? status, String? error}) {
    return ForgotPasswordState(status: status ?? this.status, error: error);
  }

  @override
  List<Object?> get props => [status, error];
}
