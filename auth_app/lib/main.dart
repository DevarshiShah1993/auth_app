import 'package:auth_app/app.dart';
import 'package:auth_app/core/di/injection.dart';
import 'package:auth_app/core/utils/env_config.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await EnvConfig.load();
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseKey,
  );
  configureDependencies();
  runApp(const App());
}
