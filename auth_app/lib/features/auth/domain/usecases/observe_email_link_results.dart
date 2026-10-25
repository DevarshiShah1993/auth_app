import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/params/no_params.dart';
import 'package:fpdart/fpdart.dart';

/// Streams the outcome of opening an email confirmation link.
///
/// Exception to the `Future<Either>` return rule: this is a stream use case.
/// `Right` means the email is confirmed (go to Sign In with a success
/// message); `Left` carries an `InvalidLinkFailure` or other failure.
class ObserveEmailLinkResults {
  /// Creates the use case.
  const ObserveEmailLinkResults(this._repository);

  final AuthRepository _repository;

  /// Starts observing link outcomes.
  Stream<Either<Failure, Unit>> call(NoParams params) =>
      _repository.emailLinkResults;
}
