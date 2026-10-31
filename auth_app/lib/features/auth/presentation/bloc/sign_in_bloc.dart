import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_in_event.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_in_state.dart';
import 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:auth_app/features/auth/presentation/bloc/sign_in_event.dart';
export 'package:auth_app/features/auth/presentation/bloc/sign_in_state.dart';
export 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';

/// Drives the Sign In form: submits through [SignInWithPassword]. Navigation
/// to Home is done by the router when the session bloc sees the new user.
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  /// Creates the bloc.
  SignInBloc({required this._signIn}) : super(const SignInState()) {
    on<SignInSubmitted>(_onSubmitted);
    on<SignInFailureDismissed>(_onFailureDismissed);
  }

  final SignInWithPassword _signIn;

  Future<void> _onSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    if (state.status == SubmitStatus.loading) return;
    emit(const SignInState(status: SubmitStatus.loading));
    final result = await _signIn(
      EmailPasswordParams(
        email: Validators.normalizeEmail(event.email),
        password: event.password,
      ),
    );
    result.match(
      (failure) =>
          emit(SignInState(status: SubmitStatus.failure, failure: failure)),
      (_) => emit(const SignInState(status: SubmitStatus.success)),
    );
  }

  void _onFailureDismissed(
    SignInFailureDismissed event,
    Emitter<SignInState> emit,
  ) {
    if (state.status != SubmitStatus.failure) return;
    emit(const SignInState());
  }
}
