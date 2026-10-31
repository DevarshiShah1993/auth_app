import 'package:auth_app/core/utils/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('throws a clear error when keys are missing', () {
    expect(() => EnvConfig.fromMap({}), throwsStateError);
  });

  test('builds config when both keys are present', () {
    final c = EnvConfig.fromMap({
      'PUBLIC_SUPABASE_URL': 'https://x.supabase.co',
      'PUBLIC_SUPABASE_PUBLISHABLE_KEY': 'k',
    });
    expect(c.supabaseUrl, 'https://x.supabase.co');
  });
}
