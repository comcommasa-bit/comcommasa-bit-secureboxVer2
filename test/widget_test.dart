import 'package:flutter_test/flutter_test.dart';

import 'package:securebox/main.dart';

void main() {
  testWidgets('SecureBox app smoke test', (tester) async {
    await tester.pumpWidget(const SecureBoxApp());

    // 初期化中はローディング表示
    expect(find.byType(SecureBoxApp), findsOneWidget);
  });
}
