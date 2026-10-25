import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/params/no_params.dart';

/// Streams the signed-in user (or `null`) on every auth change.
///
/// Exception to the `Future<Either>` return rule: this is a stream use case.
/// The stream carries no `Either`; backend errors are handled in the
/// repository and never surface as stream errors.
class ObserveAuthState {
  /// Creates the use case.
  const ObserveAuthState(this._repository);

  final AuthRepository _repository;

  /// Starts observing auth state.
  Stream<AppUser?> call(NoParams params) => _repository.authStateChanges;
}
