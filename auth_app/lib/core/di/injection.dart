import 'package:auth_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auth_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:auth_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_email_link_results.dart';
import 'package:auth_app/features/auth/domain/usecases/resend_confirmation.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_out.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_up.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/check_email_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers dependencies. Call after `Supabase.initialize`.
///
/// Repositories and data sources use `registerLazySingleton` against their
/// abstract type; Blocs use `registerFactory`. The app creates the one
/// `AuthSessionBloc` for its lifetime in `main.dart`.
void configureDependencies() {
  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl<SupabaseClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
    )
    ..registerLazySingleton(() => SignUp(sl<AuthRepository>()))
    ..registerLazySingleton(() => SignInWithPassword(sl<AuthRepository>()))
    ..registerLazySingleton(() => ResendConfirmation(sl<AuthRepository>()))
    ..registerLazySingleton(() => SignOut(sl<AuthRepository>()))
    ..registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()))
    ..registerLazySingleton(() => ObserveAuthState(sl<AuthRepository>()))
    ..registerLazySingleton(() => ObserveEmailLinkResults(sl<AuthRepository>()))
    ..registerLazySingleton(() => ResendCooldownStore())
    ..registerFactory(
      () => SignUpBloc(
        signUp: sl<SignUp>(),
        cooldownStore: sl<ResendCooldownStore>(),
      ),
    )
    ..registerFactory(
      () => CheckEmailBloc(
        resendConfirmation: sl<ResendConfirmation>(),
        cooldownStore: sl<ResendCooldownStore>(),
      ),
    )
    ..registerFactory(
      () => AuthSessionBloc(
        getCurrentUser: sl<GetCurrentUser>(),
        observeAuthState: sl<ObserveAuthState>(),
        observeEmailLinkResults: sl<ObserveEmailLinkResults>(),
        signOut: sl<SignOut>(),
      ),
    );
}
