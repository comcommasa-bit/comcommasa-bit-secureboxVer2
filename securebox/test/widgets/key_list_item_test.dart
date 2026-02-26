import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/models/key_model.dart';
import 'package:securebox/widgets/key_list_item.dart';

void main() {
  group('KeyListItem', () {
    KeyModel createKey({
      String name = 'テストキー',
      String category = 'aws',
      String type = 'api_key',
    }) {
      return KeyModel(
        id: 1,
        name: name,
        category: category,
        type: type,
        value: 'test-value',
        createdAt: DateTime(2024, 1, 1),
      );
    }

    Widget buildWidget(KeyModel key, {VoidCallback? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: KeyListItem(
            keyData: key,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('キー名が表示される', (tester) async {
      await tester.pumpWidget(buildWidget(createKey(name: 'AWS本番キー')));
      expect(find.text('AWS本番キー'), findsOneWidget);
    });

    testWidgets('カテゴリ名とタイプ名が表示される', (tester) async {
      await tester
          .pumpWidget(buildWidget(createKey(category: 'aws', type: 'api_key')));
      expect(find.text('AWS / APIキー'), findsOneWidget);
    });

    testWidgets('Stripeカテゴリの表示', (tester) async {
      await tester.pumpWidget(
          buildWidget(createKey(category: 'stripe', type: 'password')));
      expect(find.text('Stripe / パスワード'), findsOneWidget);
    });

    testWidgets('GitHubカテゴリの表示', (tester) async {
      await tester.pumpWidget(
          buildWidget(createKey(category: 'github', type: 'token')));
      expect(find.text('GitHub / トークン'), findsOneWidget);
    });

    testWidgets('OpenAIカテゴリの表示', (tester) async {
      await tester.pumpWidget(
          buildWidget(createKey(category: 'openai', type: 'api_key')));
      expect(find.text('OpenAI / APIキー'), findsOneWidget);
    });

    testWidgets('その他カテゴリの表示', (tester) async {
      await tester.pumpWidget(
          buildWidget(createKey(category: 'other', type: 'other')));
      expect(find.text('その他 / その他'), findsOneWidget);
    });

    testWidgets('タップでonTapが呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildWidget(createKey(), onTap: () => tapped = true),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('CardとListTileが含まれる', (tester) async {
      await tester.pumpWidget(buildWidget(createKey()));
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('CircleAvatarにアイコンが表示される', (tester) async {
      await tester.pumpWidget(buildWidget(createKey(category: 'aws')));
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('矢印アイコンが右端に表示される', (tester) async {
      await tester.pumpWidget(buildWidget(createKey()));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}
