import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase configuration from the git-ignored `.env` file.
class EnvConfig {
  const EnvConfig._({required this.supabaseUrl, required this.supabaseKey});

  /// Supabase project URL.
  final String supabaseUrl;

  /// Supabase publishable key (never the legacy anon key).
  final String supabaseKey;

  /// Loads `.env` and validates the two required keys.
  ///
  /// Throws a [StateError] with a clear message when a key is missing.
  static Future<EnvConfig> load() async {
    await dotenv.load();
    return fromMap(dotenv.env);
  }

  /// Builds a config from [env], throwing a [StateError] if a key is empty.
  static EnvConfig fromMap(Map<String, String> env) {
    final url = env['PUBLIC_SUPABASE_URL']?.trim() ?? '';
    final key = env['PUBLIC_SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
    final missing = <String>[
      if (url.isEmpty) 'PUBLIC_SUPABASE_URL',
      if (key.isEmpty) 'PUBLIC_SUPABASE_PUBLISHABLE_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing ${missing.join(', ')} in .env. '
        'Copy .env.example to .env and fill in the values.',
      );
    }
    return EnvConfig._(supabaseUrl: url, supabaseKey: key);
  }
}
