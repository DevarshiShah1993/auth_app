import 'dart:async';

import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_params.dart';
import 'package:auth_app/features/auth/domain/usecases/resend_confirmation.dart';
import 'package:auth_app/features/auth/presentation/bloc/check_email_event.dart';
import 'package:auth_app/features/auth/presentation/bloc/check_email_state.dart';
import 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:auth_app/features/auth/presentation/bloc/check_email_event.dart';
export 'package:auth_app/features/auth/presentation/bloc/check_email_state.dart';
export 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';

/// Resends the confirmation email with a 60 s in-memory cooldown (AC-08 to
/// AC-11, AC-13). The countdown follows an injected [CooldownTicker] and the
/// store's clock, so there are no real timers in the bloc itself.
class CheckEmailBloc extends Bloc<CheckEmailEvent, CheckEmailState> {
  /// Creates the bloc. Add [CheckEmailStarted] when the page opens.
  CheckEmailBloc({
    required this._resendConfirmation,
    required this._cooldownStore,
    this._ticker = secondTicker,
  }) : super(const CheckEmailState()) {
    on<CheckEmailStarted>(_onStarted);
    on<CheckEmailResendRequested>(_onResendRequested);
    on<CheckEmailMessageDismissed>(_onMessageDismissed);
    on<CheckEmailCooldownTicked>(_onTicked);
  }

  final ResendConfirmation _resendConfirmation;
  final ResendCooldownStore _cooldownStore;
  final CooldownTicker _ticker;
  StreamSubscription<void>? _tickSubscription;

  void _onStarted(CheckEmailStarted event, Emitter<CheckEmailState> emit) {
    final raw = event.email ?? _cooldownStore.lastEmail;
    if (raw == null) return;
    final email = Validators.normalizeEmail(raw);
    final remaining = _cooldownStore.remainingSeconds(email);
    emit(state.copyWith(email: email, remainingSeconds: remaining));
    if (remaining > 0) _startTicking();
  }

  Future<void> _onResendRequested(
    CheckEmailResendRequested event,
    Emitter<CheckEmailState> emit,
  ) async {
    if (state.status == SubmitStatus.loading) return;
    if (Validators.email(event.email) != null) return;
    final email = Validators.normalizeEmail(event.email);
    if (_cooldownStore.remainingSeconds(email) > 0) return;

    emit(
      CheckEmailState(
        status: SubmitStatus.loading,
        email: state.email,
        remainingSeconds: state.remainingSeconds,
      ),
    );
    final result = await _resendConfirmation(EmailParams(email: email));
    result.match(
      // The cooldown is not restarted on failure (AC-11).
      (failure) => emit(
        CheckEmailState(
          status: SubmitStatus.failure,
          failure: failure,
          email: state.email,
          remainingSeconds: _cooldownStore.remainingSeconds(email),
        ),
      ),
      (_) {
        _cooldownStore.start(email);
        emit(
          CheckEmailState(
            status: SubmitStatus.success,
            email: email,
            remainingSeconds: _cooldownStore.remainingSeconds(email),
          ),
        );
        _startTicking();
      },
    );
  }

  void _onMessageDismissed(
    CheckEmailMessageDismissed event,
    Emitter<CheckEmailState> emit,
  ) {
    if (state.status == SubmitStatus.loading ||
        state.status == SubmitStatus.initial) {
      return;
    }
    emit(state.copyWith(status: SubmitStatus.initial));
  }

  void _onTicked(
    CheckEmailCooldownTicked event,
    Emitter<CheckEmailState> emit,
  ) {
    final email = state.email;
    if (email == null) return;
    final remaining = _cooldownStore.remainingSeconds(email);
    if (remaining == state.remainingSeconds) return;
    emit(
      CheckEmailState(
        status: state.status,
        failure: state.failure,
        email: email,
        remainingSeconds: remaining,
      ),
    );
    if (remaining == 0) _stopTicking();
  }

  void _startTicking() {
    _tickSubscription?.cancel().ignore();
    _tickSubscription = _ticker().listen(
      (_) => add(const CheckEmailCooldownTicked()),
    );
  }

  void _stopTicking() {
    _tickSubscription?.cancel().ignore();
    _tickSubscription = null;
  }

  @override
  Future<void> close() async {
    await _tickSubscription?.cancel();
    return super.close();
  }
}
