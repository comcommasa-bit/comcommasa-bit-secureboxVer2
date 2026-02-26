import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/models/key_model.dart';

void main() {
  group('KeyModel', () {
    final testDate = DateTime(2024, 1, 1, 12, 0, 0);

    KeyModel createTestKey({int? id}) {
      return KeyModel(
        id: id,
        name: 'テストキー',
        furigana: 'てすときー',
        category: 'aws',
        type: 'api_key',
        value: 'sk-test-12345',
        memo: 'テスト用',
        createdAt: testDate,
      );
    }

    test('toJson/fromJson ラウンドトリップ', () {
      final key = createTestKey(id: 1);
      final json = key.toJson();
      final restored = KeyModel.fromJson(json);

      expect(restored.id, 1);
      expect(restored.name, 'テストキー');
      expect(restored.furigana, 'てすときー');
      expect(restored.category, 'aws');
      expect(restored.type, 'api_key');
      expect(restored.value, 'sk-test-12345');
      expect(restored.memo, 'テスト用');
      expect(restored.createdAt, testDate);
    });

    test('toMap はIDなしで動作する', () {
      final key = createTestKey();
      final map = key.toMap();

      expect(map.containsKey('id'), false);
      expect(map['name'], 'テストキー');
    });

    test('toMap はIDありで動作する', () {
      final key = createTestKey(id: 5);
      final map = key.toMap();

      expect(map['id'], 5);
    });

    test('copyWith で部分更新できる', () {
      final key = createTestKey(id: 1);
      final updated = key.copyWith(name: '更新済みキー', memo: '更新メモ');

      expect(updated.id, 1);
      expect(updated.name, '更新済みキー');
      expect(updated.memo, '更新メモ');
      expect(updated.category, 'aws'); // 変更なし
      expect(updated.value, 'sk-test-12345'); // 変更なし
    });

    test('fromMap でSQLite行から復元できる', () {
      final map = {
        'id': 1,
        'name': 'DBキー',
        'furigana': null,
        'category': 'stripe',
        'type': 'password',
        'value': 'encrypted-data',
        'memo': null,
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': null,
      };

      final key = KeyModel.fromMap(map);
      expect(key.id, 1);
      expect(key.name, 'DBキー');
      expect(key.furigana, null);
      expect(key.category, 'stripe');
    });

    test('toString で概要が表示される', () {
      final key = createTestKey(id: 1);
      expect(
        key.toString(),
        'KeyModel(id: 1, name: テストキー, category: aws, type: api_key)',
      );
    });
  });
}
