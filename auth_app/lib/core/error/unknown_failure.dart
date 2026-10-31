import 'package:auth_app/core/error/failure.dart';

/// A failure for anything unexpected.
class UnknownFailure extends Failure {
  /// Creates an unknown failure.
  const UnknownFailure(super.message);
}
