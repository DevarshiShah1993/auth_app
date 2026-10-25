import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_params.dart';
import 'package:fpdart/fpdart.dart';

/// Re-sends the sign-up confirmation email.
class ResendConfirmation {
  /// Creates the use case.
  const ResendConfirmation(this._repository);

  final AuthRepository _repository;

  /// Executes the use case.
  Future<Either<Failure, Unit>> call(EmailParams params) =>
      _repository.resendConfirmation(email: params.email);
}
