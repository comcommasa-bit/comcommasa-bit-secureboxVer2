import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/models/key_model.dart';
import 'package:securebox/widgets/key_list_item.dart';

void main() {
  final now = DateTime(2026, 3, 4, 12, 0, 0);

  KeyModel createSample({
    String name = 'テストキー',
    String category = 'AWS',
  }) {
    return KeyModel(
      id: 1,
      name: name,
      category: category,
      type: 'API Key',
      value: 'test_value',
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildTestWidget(KeyModel model, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: KeyListItem(
          keyModel: model,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('KeyListItem表示', () {
    testWidgets('キー名が表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(createSample()));
      expect(find.text('テストキー'), findsOneWidget);
    });

    testWidgets('カテゴリ・タイプが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(createSample()));
      // サブタイトルに "AWS • API Key" が含まれる
      expect(find.textContaining('AWS'), findsWidgets);
      expect(find.textContaining('API Key'), findsWidgets);
    });

    testWidgets('chevron_rightアイコンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(createSample()));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('タップでコールバックが呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          createSample(),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('異なるカテゴリでも表示できる', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(createSample(category: 'Stripe')),
      );
      expect(find.textContaining('Stripe'), findsWidgets);
    });
  });
}
