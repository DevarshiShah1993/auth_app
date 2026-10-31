// QA (T-09): static checks of the CLAUDE.md layer, security and config rules.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

Iterable<String> _imports(File f) => f.readAsLinesSync().where(
  (l) => l.startsWith('import ') || l.startsWith('export '),
);

void main() {
  group('layer rules', () {
    test('domain imports only pure Dart, fpdart, equatable and itself', () {
      for (final f in _dartFiles('lib/features/auth/domain')) {
        for (final line in _imports(f)) {
          final allowed =
              line.contains("'dart:") ||
              line.contains('package:fpdart/') ||
              line.contains('package:equatable/') ||
              line.contains('package:auth_app/features/auth/domain/') ||
              line.contains('package:auth_app/core/error/');
          expect(allowed, isTrue, reason: '${f.path}: $line');
        }
      }
    });

    test('only the data layer (and DI/main) import supabase_flutter', () {
      final offenders = _dartFiles('lib')
          .where((f) => _imports(f).any((l) => l.contains('supabase')))
          .map((f) => f.path)
          .where(
            (p) =>
                !p.startsWith('lib/features/auth/data/') &&
                p != 'lib/core/di/injection.dart' &&
                p != 'lib/main.dart',
          );
      expect(offenders, isEmpty);
    });

    test('presentation and core widgets never import data or Supabase', () {
      for (final dir in [
        'lib/features/auth/presentation',
        'lib/core/widgets',
        'lib/core/router',
      ]) {
        for (final f in _dartFiles(dir)) {
          for (final line in _imports(f)) {
            expect(line.contains('/data/'), isFalse, reason: f.path);
            expect(line.contains('supabase'), isFalse, reason: f.path);
            expect(
              line.contains('AuthRepository') ||
                  line.contains('domain/repositories'),
              isFalse,
              reason: '${f.path}: presentation must go through use cases',
            );
          }
        }
      }
    });

    test('every use case has a single public call returning Either', () {
      // The two stream use cases are a documented exception (they return
      // Stream, see their doc comments); see bugs.md note N-02.
      const streamUseCases = {
        'observe_auth_state.dart',
        'observe_email_link_results.dart',
      };
      final files = Directory('lib/features/auth/domain/usecases')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in files) {
        final text = f.readAsStringSync();
        expect(RegExp(r'\bcall\(').allMatches(text).length, 1, reason: f.path);
        if (streamUseCases.any(f.path.endsWith)) {
          expect(text.contains('Stream<'), isTrue, reason: f.path);
        } else {
          expect(
            text.contains('Future<Either<Failure,'),
            isTrue,
            reason: f.path,
          );
        }
      }
    });

    test('DI registers repository and data source on abstract types', () {
      final di = File('lib/core/di/injection.dart').readAsStringSync();
      expect(di, contains('registerLazySingleton<AuthRemoteDataSource>'));
      expect(di, contains('registerLazySingleton<AuthRepository>'));
      expect(di, contains('registerFactory'));
    });
  });

  group('security and code standards', () {
    test('no print / debugPrint / log calls in lib (AC-31)', () {
      final pattern = RegExp(
        r'(^|[^A-Za-z_])(print|debugPrint|log|debugPrintStack)\(|dart:developer',
      );
      for (final f in _dartFiles('lib')) {
        expect(pattern.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
      }
    });

    test('no dynamic in lib', () {
      for (final f in _dartFiles('lib')) {
        expect(
          RegExp(r'\bdynamic\b').hasMatch(f.readAsStringSync()),
          isFalse,
          reason: f.path,
        );
      }
    });

    test('no hardcoded colours or text styles in pages and widgets', () {
      final pattern = RegExp(
        r'Color\(0x|(?<![A-Za-z])Colors\.|TextStyle\(|fontFamily',
      );
      for (final dir in [
        'lib/features/auth/presentation',
        'lib/core/widgets',
      ]) {
        for (final f in _dartFiles(dir)) {
          expect(
            pattern.hasMatch(f.readAsStringSync()),
            isFalse,
            reason: f.path,
          );
        }
      }
    });

    test('no service-role / secret / legacy anon key in tracked sources', () {
      final pattern = RegExp(r'service_role|sb_secret_|eyJ[A-Za-z0-9_-]{20,}');
      for (final dir in ['lib', 'test', 'android/app/src', 'ios/Runner']) {
        for (final f in Directory(dir).listSync(recursive: true)) {
          if (f is! File) continue;
          if (f.path.endsWith('architecture_rules_test.dart')) continue;
          String text;
          try {
            text = f.readAsStringSync();
          } on FileSystemException {
            continue; // Binary file.
          }
          expect(pattern.hasMatch(text), isFalse, reason: f.path);
        }
      }
    });

    test('.env is git-ignored and not tracked (AC-32)', () {
      final ignored = Process.runSync('git', ['check-ignore', '.env']);
      expect(ignored.exitCode, 0);
      final tracked = Process.runSync('git', ['ls-files', '.env']);
      expect((tracked.stdout as String).trim(), isEmpty);
    });

    test('.env.example has the two keys with empty values (AC-32)', () {
      final lines = File('.env.example')
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty && !l.startsWith('#'))
          .toList();
      expect(lines.map((l) => l.split('=').first).toSet(), {
        'PUBLIC_SUPABASE_URL',
        'PUBLIC_SUPABASE_PUBLISHABLE_KEY',
      });
      for (final l in lines) {
        expect(l.substring(l.indexOf('=') + 1).trim(), isEmpty, reason: l);
      }
    });
  });

  group('deep link config (T-10)', () {
    final constants = File('lib/core/utils/app_constants.dart')
        .readAsStringSync();
    final url = RegExp(r"authRedirectUrl = '([^']+)'")
        .firstMatch(constants)!
        .group(1)!; // Test: the constant must exist.
    final uri = Uri.parse(url);

    test('Android intent filter matches AppConstants.authRedirectUrl', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('android:scheme="${uri.scheme}"'));
      expect(manifest, contains('android:host="${uri.host}"'));
      expect(manifest, contains('android.intent.category.BROWSABLE'));
    });

    test('iOS URL scheme matches AppConstants.authRedirectUrl', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('<string>${uri.scheme}</string>'));
    });
  });
}
