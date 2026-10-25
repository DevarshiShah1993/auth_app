import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:fpdart/fpdart.dart';

/// Signs in with email and password.
class SignInWithPassword {
  /// Creates the use case.
  const SignInWithPassword(this._repository);

  final AuthRepository _repository;

  /// Executes the use case.
  Future<Either<Failure, AppUser>> call(EmailPasswordParams params) =>
      _repository.signInWithPassword(
        email: params.email,
        password: params.password,
      );
}
