import 'package:auth_app/features/auth/data/models/auth_event_type.dart';
import 'package:auth_app/features/auth/data/models/user_model.dart';
import 'package:equatable/equatable.dart';

/// One auth state change reported by the data source.
class AuthStateEventModel extends Equatable {
  /// Creates an event.
  const AuthStateEventModel({required this.type, this.user}) : error = null;

  /// Creates an [AuthEventType.error] event carrying the raw [error].
  const AuthStateEventModel.error(Object this.error)
    : type = AuthEventType.error,
      user = null;

  /// Kind of change.
  final AuthEventType type;

  /// User of the session after the change, if any.
  final UserModel? user;

  /// The error for [AuthEventType.error] events.
  final Object? error;

  @override
  List<Object?> get props => [type, user, error];
}
