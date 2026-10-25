import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:fpdart/fpdart.dart';

/// Registers an account with email and password; a confirmation email is sent.
class SignUp {
  /// Creates the use case.
  const SignUp(this._repository);

  final AuthRepository _repository;

  /// Executes the use case.
  Future<Either<Failure, Unit>> call(EmailPasswordParams params) =>
      _repository.signUp(email: params.email, password: params.password);
}
