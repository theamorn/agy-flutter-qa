import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/auth_failure.dart';
import '../../services/auth_service.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

/// Drives the forgot-password screen: requests a reset link for an email.
class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({required AuthService authService})
    : _authService = authService,
      super(const ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  final AuthService _authService;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(state.copyWith(status: ForgotPasswordStatus.submitting));
    try {
      await _authService.sendPasswordReset(email: event.email);
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.success));
    } on AuthFailure catch (failure) {
      emit(
        ForgotPasswordState(
          status: ForgotPasswordStatus.failure,
          error: failure.message,
        ),
      );
    }
  }
}
