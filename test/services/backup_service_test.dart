import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/models/key_model.dart';
import 'package:securebox/services/crypto_service.dart';

/// backup_service.dart のロジックテスト
///
/// BackupService自体はFilePicker（デバイス依存）を使うため直接テスト不可。
/// ここではバックアップの核心ロジック（JSON化→暗号化→復号→復元）を検証する。
void main() {
  const testPassword = 'BackupTestPassword!';
  final now = DateTime(2026, 3, 4, 12, 0, 0);

  List<KeyModel> createSampleKeys() {
    return [
      KeyModel(
        id: 1,
        name: 'AWS本番キー',
        category: 'AWS',
        type: 'API Key',
        value: 'AKIA1234',
        memo: 'テスト',
        createdAt: now,
        updatedAt: now,
        tags: ['本番'],
      ),
      KeyModel(
        id: 2,
        name: 'Stripeシークレット',
        category: 'Stripe',
        type: 'Secret Key',
        value: 'sk_live_xxxx',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  group('バックアップ形式（JSON化→暗号化→復号→復元）', () {
    test('キーリストをJSON化して暗号化・復号できる', () {
      final keys = createSampleKeys();
      final jsonList = keys.map((k) => k.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      // 暗号化
      final encrypted = CryptoService.encryptText(
        jsonString,
        testPassword,
      );
      expect(encrypted, isNot(equals(jsonString)));

      // 復号
      final decrypted = CryptoService.decryptText(
        encrypted,
        testPassword,
      );
      expect(decrypted, jsonString);
    });

    test('復号したJSONからKeyModelを正しく復元できる', () {
      final keys = createSampleKeys();
      final jsonList = keys.map((k) => k.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      final encrypted = CryptoService.encryptText(
        jsonString,
        testPassword,
      );
      final decrypted = CryptoService.decryptText(
        encrypted,
        testPassword,
      );

      final List<dynamic> restoredList = jsonDecode(decrypted);
      final restoredKeys = restoredList
          .map((item) => KeyModel.fromMap(item as Map<String, dynamic>))
          .toList();

      expect(restoredKeys.length, 2);
      expect(restoredKeys[0].name, 'AWS本番キー');
      expect(restoredKeys[0].tags, ['本番']);
      expect(restoredKeys[1].name, 'Stripeシークレット');
      expect(restoredKeys[1].category, 'Stripe');
    });

    test('間違ったパスワードでは復号に失敗する', () {
      final keys = createSampleKeys();
      final jsonString = jsonEncode(keys.map((k) => k.toMap()).toList());
      final encrypted = CryptoService.encryptText(
        jsonString,
        testPassword,
      );

      expect(
        () => CryptoService.decryptText(encrypted, 'WrongPassword!'),
        throwsA(isA<Object>()),
      );
    });

    test('インポート時にIDを除外して新規データとして扱える', () {
      final keys = createSampleKeys();
      final jsonList = keys.map((k) => k.toMap()).toList();

      // インポート処理のシミュレーション
      for (final map in jsonList) {
        map.remove('id');
        map['created_at'] ??= DateTime.now().toIso8601String();
        map['updated_at'] ??= DateTime.now().toIso8601String();

        final restored = KeyModel.fromMap(map);
        expect(restored.id, isNull);
        expect(restored.name, isNotEmpty);
      }
    });

    test('空リストのバックアップも処理できる', () {
      final jsonString = jsonEncode([]);
      final encrypted = CryptoService.encryptText(
        jsonString,
        testPassword,
      );
      final decrypted = CryptoService.decryptText(
        encrypted,
        testPassword,
      );

      final List<dynamic> restoredList = jsonDecode(decrypted);
      expect(restoredList, isEmpty);
    });
  });
}
