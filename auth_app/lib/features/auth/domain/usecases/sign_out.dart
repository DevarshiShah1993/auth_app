import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/params/no_params.dart';
import 'package:fpdart/fpdart.dart';

/// Signs out; the local session is cleared even if this fails.
class SignOut {
  /// Creates the use case.
  const SignOut(this._repository);

  final AuthRepository _repository;

  /// Executes the use case.
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.signOut();
}
