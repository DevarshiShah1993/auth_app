import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_up.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_up_event.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_up_state.dart';
import 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:auth_app/features/auth/presentation/bloc/sign_up_event.dart';
export 'package:auth_app/features/auth/presentation/bloc/sign_up_state.dart';
export 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';

/// Drives the Sign Up form: submits through [SignUp] and starts the resend
/// cooldown when the confirmation email was sent (AC-09).
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  /// Creates the bloc.
  SignUpBloc({required this._signUp, required this._cooldownStore})
    : super(const SignUpState()) {
    on<SignUpSubmitted>(_onSubmitted);
    on<SignUpFailureDismissed>(_onFailureDismissed);
  }

  final SignUp _signUp;
  final ResendCooldownStore _cooldownStore;

  Future<void> _onSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    if (state.status == SubmitStatus.loading) return;
    final email = Validators.normalizeEmail(event.email);
    emit(const SignUpState(status: SubmitStatus.loading));
    final result = await _signUp(
      EmailPasswordParams(email: email, password: event.password),
    );
    result.match(
      (failure) =>
          emit(SignUpState(status: SubmitStatus.failure, failure: failure)),
      (_) {
        _cooldownStore.start(email);
        emit(SignUpState(status: SubmitStatus.success, email: email));
      },
    );
  }

  void _onFailureDismissed(
    SignUpFailureDismissed event,
    Emitter<SignUpState> emit,
  ) {
    if (state.status != SubmitStatus.failure) return;
    emit(const SignUpState());
  }
}
