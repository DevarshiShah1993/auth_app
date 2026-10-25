import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/params/no_params.dart';
import 'package:fpdart/fpdart.dart';

/// Returns the user of the stored session, or null when signed out.
class GetCurrentUser {
  /// Creates the use case.
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  /// Executes the use case.
  Future<Either<Failure, AppUser?>> call(NoParams params) =>
      Future.value(right(_repository.currentUser));
}
