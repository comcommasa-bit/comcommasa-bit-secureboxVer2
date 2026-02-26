import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../config/constants.dart';
import '../models/key_model.dart';

/// SQLiteストレージサービス
///
/// キーデータのCRUD操作を提供する
class StorageService {
  static Database? _database;

  /// データベースインスタンスを取得（シングルトン）
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// データベースを初期化
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, Constants.dbName);

    return openDatabase(
      path,
      version: Constants.dbVersion,
      onCreate: _onCreate,
    );
  }

  /// テーブル作成
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        furigana TEXT,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        memo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  /// キーを追加
  ///
  /// 無料版の場合、保存数が上限に達していたら例外をスロー
  static Future<int> insertKey(KeyModel key, {bool isPro = false}) async {
    if (!isPro) {
      final count = await getKeyCount();
      if (count >= Constants.maxFreeKeys) {
        throw Exception(
          '無料版の保存上限（${Constants.maxFreeKeys}個）に達しています。有料版にアップグレードしてください。',
        );
      }
    }

    final db = await database;
    return db.insert('keys', key.toMap());
  }

  /// キーを更新
  static Future<int> updateKey(KeyModel key) async {
    if (key.id == null) {
      throw ArgumentError('更新するキーにはIDが必要です');
    }

    final db = await database;
    final updatedKey = key.copyWith(updatedAt: DateTime.now());
    return db.update(
      'keys',
      updatedKey.toMap(),
      where: 'id = ?',
      whereArgs: [key.id],
    );
  }

  /// キーを削除
  static Future<int> deleteKey(int id) async {
    final db = await database;
    return db.delete(
      'keys',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// IDでキーを取得
  static Future<KeyModel?> getKeyById(int id) async {
    final db = await database;
    final maps = await db.query(
      'keys',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return KeyModel.fromMap(maps.first);
  }

  /// 全キーを取得（作成日時の降順）
  static Future<List<KeyModel>> getAllKeys() async {
    final db = await database;
    final maps = await db.query('keys', orderBy: 'created_at DESC');
    return maps.map((map) => KeyModel.fromMap(map)).toList();
  }

  /// カテゴリ別にキーを取得
  static Future<List<KeyModel>> getKeysByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'keys',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => KeyModel.fromMap(map)).toList();
  }

  /// キーの総数を取得
  static Future<int> getKeyCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM keys');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// データベースを閉じる
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 全データを取得（バックアップ用）
  static Future<List<Map<String, dynamic>>> exportAll() async {
    final db = await database;
    return db.query('keys');
  }

  /// データをインポート（復元用）
  static Future<void> importAll(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('keys'); // 既存データを削除
    for (final row in data) {
      batch.insert('keys', row);
    }
    await batch.commit(noResult: true);
  }
}
