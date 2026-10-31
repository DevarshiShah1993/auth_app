import 'package:auth_app/core/error/failure.dart';

/// A failure caused by missing or failing connectivity.
class NetworkFailure extends Failure {
  /// Creates a network failure.
  const NetworkFailure(super.message);
}
