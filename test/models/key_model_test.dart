import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/models/key_model.dart';

void main() {
  final now = DateTime(2026, 3, 4, 12, 0, 0);

  KeyModel createSample({int? id, List<String>? tags, DateTime? expiresAt}) {
    return KeyModel(
      id: id,
      name: 'AWS本番キー',
      category: 'AWS',
      type: 'API Key',
      value: 'AKIA1234567890',
      memo: 'テストメモ',
      createdAt: now,
      updatedAt: now,
      tags: tags,
      expiresAt: expiresAt,
    );
  }

  group('KeyModel基本', () {
    test('必須フィールドで生成できる', () {
      final key = createSample();
      expect(key.name, 'AWS本番キー');
      expect(key.category, 'AWS');
      expect(key.type, 'API Key');
      expect(key.value, 'AKIA1234567890');
      expect(key.memo, 'テストメモ');
      expect(key.id, isNull);
      expect(key.tags, isNull);
      expect(key.expiresAt, isNull);
    });
  });

  group('toMap / fromMap', () {
    test('idなしでtoMapするとidキーが含まれない', () {
      final map = createSample().toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['name'], 'AWS本番キー');
      expect(map['created_at'], now.toIso8601String());
    });

    test('idありでtoMapするとidキーが含まれる', () {
      final map = createSample(id: 42).toMap();
      expect(map['id'], 42);
    });

    test('fromMapで正しく復元できる', () {
      final original = createSample(id: 1);
      final map = original.toMap();
      final restored = KeyModel.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.type, original.type);
      expect(restored.value, original.value);
      expect(restored.memo, original.memo);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('tagsがJSON文字列として保存・復元される', () {
      final key = createSample(tags: ['本番', '重要']);
      final map = key.toMap();

      expect(map['tags'], jsonEncode(['本番', '重要']));

      final restored = KeyModel.fromMap(map);
      expect(restored.tags, ['本番', '重要']);
    });

    test('expiresAtが保存・復元される', () {
      final expires = DateTime(2027, 1, 1);
      final key = createSample(expiresAt: expires);
      final map = key.toMap();

      expect(map['expires_at'], expires.toIso8601String());

      final restored = KeyModel.fromMap(map);
      expect(restored.expiresAt, expires);
    });

    test('tagsとexpiresAtがnullの場合も正しく復元される', () {
      final map = createSample().toMap();
      final restored = KeyModel.fromMap(map);

      expect(restored.tags, isNull);
      expect(restored.expiresAt, isNull);
    });
  });

  group('toJson / fromJson', () {
    test('JSON文字列に変換・復元できる', () {
      final original = createSample(id: 5, tags: ['テスト']);
      final json = original.toJson();
      final restored = KeyModel.fromJson(json);

      expect(restored.id, 5);
      expect(restored.name, original.name);
      expect(restored.tags, ['テスト']);
    });
  });

  group('copyWith', () {
    test('一部フィールドだけ変更できる', () {
      final original = createSample(id: 1);
      final updated = original.copyWith(
        name: '変更後の名前',
        updatedAt: DateTime(2026, 6, 1),
      );

      expect(updated.name, '変更後の名前');
      expect(updated.updatedAt, DateTime(2026, 6, 1));
      // 変更していないフィールドは元のまま
      expect(updated.id, 1);
      expect(updated.category, 'AWS');
      expect(updated.value, 'AKIA1234567890');
    });

    test('元のインスタンスは変更されない（イミュータブル）', () {
      final original = createSample(id: 1);
      original.copyWith(name: '別の名前');

      expect(original.name, 'AWS本番キー');
    });
  });
}
