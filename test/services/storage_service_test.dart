import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:securebox/models/key_model.dart';
import 'package:securebox/services/storage_service.dart';

void main() {
  // テスト用にFFIを使う（デバイス不要）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final now = DateTime.now();

  KeyModel createSample({String name = 'テストキー', String category = 'AWS'}) {
    return KeyModel(
      name: name,
      category: category,
      type: 'API Key',
      value: 'encrypted_value_here',
      memo: 'テスト',
      createdAt: now,
      updatedAt: now,
    );
  }

  late StorageService storage;

  setUp(() async {
    // テストごとにDBをリセット
    storage = StorageService();
    await storage.deleteAllKeys();
  });

  group('CRUD操作', () {
    test('キーを追加して取得できる', () async {
      final id = await storage.insertKey(createSample());
      expect(id, greaterThan(0));

      final key = await storage.getKeyById(id);
      expect(key, isNotNull);
      expect(key!.name, 'テストキー');
      expect(key.category, 'AWS');
    });

    test('存在しないIDはnullを返す', () async {
      final key = await storage.getKeyById(99999);
      expect(key, isNull);
    });

    test('全件取得できる（新しい順）', () async {
      await storage.insertKey(createSample(name: '1番目'));
      // 少し遅らせて異なるupdated_atにする
      await storage.insertKey(
        KeyModel(
          name: '2番目',
          category: 'Stripe',
          type: 'Secret',
          value: 'val',
          createdAt: now,
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );

      final keys = await storage.getAllKeys();
      expect(keys.length, 2);
      // 新しい順
      expect(keys.first.name, '2番目');
    });

    test('カテゴリ別に取得できる', () async {
      await storage.insertKey(createSample(category: 'AWS'));
      await storage.insertKey(createSample(category: 'Stripe'));
      await storage.insertKey(createSample(category: 'AWS'));

      final awsKeys = await storage.getKeysByCategory('AWS');
      expect(awsKeys.length, 2);

      final stripeKeys = await storage.getKeysByCategory('Stripe');
      expect(stripeKeys.length, 1);
    });

    test('キーを更新できる', () async {
      final id = await storage.insertKey(createSample());
      final key = await storage.getKeyById(id);
      final updated = key!.copyWith(name: '更新後の名前');

      final count = await storage.updateKey(updated);
      expect(count, 1);

      final result = await storage.getKeyById(id);
      expect(result!.name, '更新後の名前');
    });

    test('キーを削除できる', () async {
      final id = await storage.insertKey(createSample());
      final count = await storage.deleteKey(id);
      expect(count, 1);

      final key = await storage.getKeyById(id);
      expect(key, isNull);
    });
  });

  group('件数管理', () {
    test('getKeyCountが正しい件数を返す', () async {
      expect(await storage.getKeyCount(), 0);

      await storage.insertKey(createSample());
      expect(await storage.getKeyCount(), 1);

      await storage.insertKey(createSample(name: '2つ目'));
      expect(await storage.getKeyCount(), 2);
    });

    test('deleteAllKeysで全件削除される', () async {
      await storage.insertKey(createSample());
      await storage.insertKey(createSample(name: '2つ目'));

      final deleted = await storage.deleteAllKeys();
      expect(deleted, 2);
      expect(await storage.getKeyCount(), 0);
    });
  });

  group('無料版制限', () {
    test('10件未満なら追加可能', () async {
      for (var i = 0; i < 9; i++) {
        await storage.insertKey(createSample(name: 'key$i'));
      }
      expect(await storage.canAddKey(), isTrue);
    });

    test('10件に達すると追加不可', () async {
      for (var i = 0; i < 10; i++) {
        await storage.insertKey(createSample(name: 'key$i'));
      }
      expect(await storage.canAddKey(), isFalse);
    });

    test('制限到達時にinsertKeyがExceptionを投げる', () async {
      for (var i = 0; i < 10; i++) {
        await storage.insertKey(createSample(name: 'key$i'));
      }

      expect(
        () => storage.insertKey(createSample(name: '11個目')),
        throwsA(isA<Exception>()),
      );
    });
  });
}
