import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late ResendCooldownStore store;

  setUp(() {
    now = DateTime(2026, 10, 25, 12);
    store = ResendCooldownStore(() => now);
  });

  test('no cooldown before start', () {
    expect(store.remainingSeconds('a@b.co'), 0);
    expect(store.lastEmail, isNull);
  });

  test('start gives 60 s and counts down, case-insensitive', () {
    store.start('A@B.co');
    expect(store.remainingSeconds('a@b.co'), 60);
    now = now.add(const Duration(milliseconds: 20500));
    expect(store.remainingSeconds(' a@B.CO '), 40);
    now = now.add(const Duration(seconds: 40));
    expect(store.remainingSeconds('a@b.co'), 0);
    expect(store.lastEmail, 'a@b.co');
  });

  test('cooldown is per email', () {
    store.start('a@b.co');
    expect(store.remainingSeconds('c@d.co'), 0);
  });
}
