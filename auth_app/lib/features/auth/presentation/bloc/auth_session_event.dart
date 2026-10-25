import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/presentation/bloc/email_link_result.dart';
import 'package:equatable/equatable.dart';

part 'auth_session_link_result_consumed.dart';
part 'auth_session_link_result_received.dart';
part 'auth_session_logout_requested.dart';
part 'auth_session_started.dart';
part 'auth_session_user_changed.dart';

/// Base class of all [AuthSessionBloc] events.
sealed class AuthSessionEvent extends Equatable {
  /// Creates an event.
  const AuthSessionEvent();

  @override
  List<Object?> get props => [];
}
