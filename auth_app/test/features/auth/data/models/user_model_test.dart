import 'package:auth_app/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user({String? email, String? confirmedAt}) => User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
  email: email,
  emailConfirmedAt: confirmedAt,
);

void main() {
  test('maps a confirmed user', () {
    final model = UserModel.fromSupabase(
      _user(email: 'a@b.co', confirmedAt: '2026-01-01T00:00:00Z'),
    );
    expect(model.id, 'u1');
    expect(model.email, 'a@b.co');
    expect(model.emailConfirmed, isTrue);
  });

  test('maps an unconfirmed user', () {
    expect(
      UserModel.fromSupabase(_user(email: 'a@b.co')).emailConfirmed,
      isFalse,
    );
  });

  test('uses empty email when missing', () {
    expect(UserModel.fromSupabase(_user()).email, '');
  });
}
