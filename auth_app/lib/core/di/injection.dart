import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers dependencies. Call after `Supabase.initialize`.
///
/// Repositories and data sources use `registerLazySingleton` against their
/// abstract type; Blocs use `registerFactory` (added in later tasks).
void configureDependencies() {
  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }
}
