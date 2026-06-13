import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/app_user.dart';
import '../../models/auth_failure.dart';
import '../../services/auth_service.dart';

part 'register_event.dart';
part 'register_state.dart';

/// Drives the register screen: submits a new account and reports the outcome.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required AuthService authService})
    : _authService = authService,
      super(const RegisterState()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  final AuthService _authService;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(status: RegisterStatus.submitting));
    try {
      final user = await _authService.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(RegisterState(status: RegisterStatus.success, user: user));
    } on AuthFailure catch (failure) {
      emit(
        RegisterState(status: RegisterStatus.failure, error: failure.message),
      );
    }
  }
}
