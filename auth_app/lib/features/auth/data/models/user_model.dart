import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [AppUser] built from a Supabase [User].
class UserModel extends AppUser {
  /// Creates a model.
  const UserModel({
    required super.id,
    required super.email,
    required super.emailConfirmed,
  });

  /// Maps a Supabase user. Only id, email and confirmation state are kept.
  factory UserModel.fromSupabase(User user) => UserModel(
    id: user.id,
    email: user.email ?? '',
    emailConfirmed: user.emailConfirmedAt != null,
  );
}
