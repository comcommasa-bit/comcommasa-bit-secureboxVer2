import 'package:flutter_test/flutter_test.dart';

import 'package:securebox/main.dart';

void main() {
  testWidgets('SecureBox app smoke test', (tester) async {
    await tester.pumpWidget(const SecureBoxApp());

    // アプリ名が表示されること
    expect(find.text('SecureBox'), findsOneWidget);
  });
}
