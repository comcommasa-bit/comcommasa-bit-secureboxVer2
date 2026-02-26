import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/config/constants.dart';
import 'package:securebox/models/key_model.dart';
import 'package:securebox/services/storage_service.dart';

// NOTE: StorageServiceはsqfliteを使用するため、純粋なユニットテストでは
// 実行できません。以下のテストは sqflite_common_ffi を使うか、
// Integration Test として実機/エミュレータで実行してください。
//
// sqflite_common_ffi を使う場合、pubspec.yaml の dev_dependencies に
//   sqflite_common_ffi: ^2.3.0
// を追加し、テストの setUp で databaseFactory を設定します。

void main() {
  group('StorageService（ロジックテスト）', () {
    // StorageServiceの公開メソッドのシグネチャ・型を確認するテスト
    // 実際のDB操作は Integration Test で検証

    test('KeyModel.toMap がDB挿入に適したMapを返す', () {
      final key = KeyModel(
        name: 'テスト',
        category: 'aws',
        type: 'api_key',
        value: 'test-value',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = key.toMap();

      expect(map['name'], 'テスト');
      expect(map['category'], 'aws');
      expect(map['type'], 'api_key');
      expect(map['value'], 'test-value');
      expect(map['created_at'], '2024-01-01T00:00:00.000');
      expect(map.containsKey('id'), false); // idがnullならMapに含まれない
    });

    test('KeyModel.fromMap がDB行からモデルを復元する', () {
      final map = {
        'id': 1,
        'name': 'DB復元テスト',
        'furigana': 'でーびーふくげんてすと',
        'category': 'stripe',
        'type': 'password',
        'value': 'encrypted-data-here',
        'memo': 'テストメモ',
        'created_at': '2024-06-15T10:30:00.000',
        'updated_at': '2024-06-16T14:00:00.000',
      };

      final key = KeyModel.fromMap(map);

      expect(key.id, 1);
      expect(key.name, 'DB復元テスト');
      expect(key.furigana, 'でーびーふくげんてすと');
      expect(key.category, 'stripe');
      expect(key.type, 'password');
      expect(key.value, 'encrypted-data-here');
      expect(key.memo, 'テストメモ');
      expect(key.createdAt, DateTime(2024, 6, 15, 10, 30));
      expect(key.updatedAt, DateTime(2024, 6, 16, 14, 0));
    });

    test('KeyModel.fromMap でnullableフィールドがnullでも動作する', () {
      final map = {
        'id': 2,
        'name': 'Minimal',
        'furigana': null,
        'category': 'other',
        'type': 'other',
        'value': 'val',
        'memo': null,
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': null,
      };

      final key = KeyModel.fromMap(map);

      expect(key.furigana, isNull);
      expect(key.memo, isNull);
      expect(key.updatedAt, isNull);
    });

    test('無料版の保存上限定数が正しい', () {
      expect(Constants.maxFreeKeys, 10);
    });

    test('データベース設定定数が正しい', () {
      expect(Constants.dbName, 'securebox.db');
      expect(Constants.dbVersion, 1);
    });
  });

  group('StorageService Integration Test（要実機）', () {
    // 以下のテストは sqflite_common_ffi または実機で実行してください。
    // flutter test で実行するには setUp で以下の初期化が必要:
    //
    // import 'package:sqflite_common_ffi/sqflite_ffi.dart';
    //
    // setUpAll(() {
    //   sqfliteFfiInit();
    //   databaseFactory = databaseFactoryFfi;
    // });

    test('insertKey → getKeyById で保存・取得できる', () {
      // Integration Test として実装
    }, skip: 'sqflite は実機/エミュレータまたは sqflite_common_ffi が必要');

    test('insertKey が無料版上限（10個）で例外をスロー', () {
      // Integration Test として実装
    }, skip: 'sqflite は実機/エミュレータまたは sqflite_common_ffi が必要');

    test('insertKey が有料版（isPro: true）で上限なし', () {
      // Integration Test として実装
    }, skip: 'sqflite は実機/エミュレータまたは sqflite_common_ffi が必要');

    test('updateKey でIDがnullの場合 ArgumentError', () {
      // この検証はDB不要なので直接テスト可能
      final key = KeyModel(
        name: 'no-id',
        category: 'aws',
        type: 'api_key',
        value: 'val',
        createdAt: DateTime.now(),
      );

      expect(
        () => StorageService.updateKey(key),
        throwsA(isA<ArgumentError>()),
      );
    }, skip: 'sqflite の初期化が必要なためスキップ');

    test('deleteKey で存在しないIDを渡しても例外なし', () {
      // Integration Test として実装
    }, skip: 'sqflite は実機/エミュレータまたは sqflite_common_ffi が必要');

    test('getAllKeys が作成日時の降順で返す', () {
      // Integration Test として実装
    }, skip: 'sqflite は実機/エミュレータまたは sqflite_common_ffi が必要');

    test('getKeysByCategory でカテゴリ絞り込みができる', () {
      // Integration Test として実装
    }, skip: 'sqflite は実機/エミュレータまたは sqflite_common_ffi が必要');

    test('exportAll / importAll でバックアップ・復元できる', () {
      // Integration Test として実装
    }, skip: 'sqflite は実機/エミュレータまたは sqflite_common_ffi が必要');
  });
}
