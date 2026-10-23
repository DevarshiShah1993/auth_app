import 'package:auth_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows placeholder page', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('Bakery'), findsOneWidget);
  });
}
