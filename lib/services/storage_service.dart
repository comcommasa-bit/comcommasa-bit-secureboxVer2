/// ストレージサービス
///
/// SQLiteを使用したデータの永続化を担当する。
/// 暗号化されたデータをそのまま保存・取得する。
library;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../config/constants.dart';
import '../models/key_model.dart';

/// SQLite操作を行うストレージサービス（シングルトン）
class StorageService {
  // シングルトンパターン
  static final StorageService _instance =
      StorageService._internal();

  /// シングルトンインスタンスを取得する
  factory StorageService() => _instance;

  StorageService._internal();

  Database? _database;

  /// データベースインスタンスを取得する
  ///
  /// 未初期化の場合は自動で初期化する。
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// データベースを初期化する
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'securebox.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// テーブルを作成する（新規インストール時）
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE keys(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        memo TEXT,
        username TEXT,
        email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tags TEXT,
        expires_at TEXT
      )
    ''');
  }

  /// DBマイグレーション（既存ユーザーのアップグレード時）
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE keys ADD COLUMN username TEXT');
      await db.execute('ALTER TABLE keys ADD COLUMN email TEXT');
    }
  }

  /// キーを新規追加する
  ///
  /// [key] 保存するキーデータ
  ///
  /// Returns: 追加されたキーのID
  /// Throws: [Exception] 無料版で保存数制限に達した場合
  Future<int> insertKey(KeyModel key) async {
    final canAdd = await canAddKey();
    if (!canAdd) {
      throw Exception(
        '無料版の保存数制限'
        '（${AppConstants.freePlanLimit}件）に達しました。',
      );
    }

    final db = await database;
    return db.insert('keys', key.toMap());
  }

  /// IDでキーを取得する
  ///
  /// [id] 取得するキーのID
  ///
  /// Returns: キーデータ（存在しない場合はnull）
  Future<KeyModel?> getKeyById(int id) async {
    final db = await database;
    final maps = await db.query(
      'keys',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return KeyModel.fromMap(maps.first);
  }

  /// 全てのキーを取得する
  ///
  /// Returns: キーデータのリスト（新しい順）
  Future<List<KeyModel>> getAllKeys() async {
    final db = await database;
    final maps = await db.query(
      'keys',
      orderBy: 'updated_at DESC',
    );

    return maps.map(KeyModel.fromMap).toList();
  }

  /// カテゴリ別にキーを取得する
  ///
  /// [category] カテゴリ名
  ///
  /// Returns: 該当カテゴリのキーリスト
  Future<List<KeyModel>> getKeysByCategory(
    String category,
  ) async {
    final db = await database;
    final maps = await db.query(
      'keys',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'updated_at DESC',
    );

    return maps.map(KeyModel.fromMap).toList();
  }

  /// キーを更新する
  ///
  /// [key] 更新するキーデータ（idが必要）
  ///
  /// Returns: 更新された行数
  Future<int> updateKey(KeyModel key) async {
    final db = await database;
    return db.update(
      'keys',
      key.toMap(),
      where: 'id = ?',
      whereArgs: [key.id],
    );
  }

  /// キーを削除する
  ///
  /// [id] 削除するキーのID
  ///
  /// Returns: 削除された行数
  Future<int> deleteKey(int id) async {
    final db = await database;
    return db.delete(
      'keys',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 現在の保存件数を取得する
  ///
  /// Returns: 保存されているキーの数
  Future<int> getKeyCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM keys',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// キーを追加できるか判定する
  ///
  /// 無料版: 10個未満なら追加可能
  /// 有料版: 常に追加可能
  ///
  /// Returns: 追加可能なら true
  Future<bool> canAddKey() async {
    if (AppConstants.isPro) return true;

    final count = await getKeyCount();
    return count < AppConstants.freePlanLimit;
  }

  /// 全キーを削除する（リセット用）
  ///
  /// Returns: 削除された行数
  Future<int> deleteAllKeys() async {
    final db = await database;
    return db.delete('keys');
  }

  /// データベースを閉じる
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
