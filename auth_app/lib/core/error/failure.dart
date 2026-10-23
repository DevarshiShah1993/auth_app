import 'package:equatable/equatable.dart';

/// Base class for all functional errors returned as `Left` in `Either`.
abstract class Failure extends Equatable {
  /// Creates a failure with a user-presentable [message].
  const Failure(this.message);

  /// Human-readable description of what went wrong.
  final String message;

  @override
  List<Object?> get props => [message];
}
