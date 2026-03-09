/// キーデータモデル
///
/// パスワードやAPIキーなどの保存データを表す。
/// SQLiteへの保存・復元、JSON変換に対応。
library;

import 'dart:convert';

/// キーデータを表すモデルクラス
class KeyModel {
  /// SQLiteのAUTOINCREMENT ID
  final int? id;

  /// キーの名前（例: "AWS本番キー"）
  final String name;

  /// カテゴリ（Stripe, AWS, OpenAI, Google, GitHub, その他）
  final String category;

  /// キーの種類（例: "API Key", "Password", "Secret"）
  final String type;

  /// キーの値（暗号化済み文字列）
  final String value;

  /// メモ（任意）
  final String? memo;

  /// ユーザー名（パスワード保管用、任意）
  final String? username;

  /// メールアドレス（パスワード保管用、任意）
  final String? email;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime updatedAt;

  /// ★有料版の余白: タグ（今はnull可）
  final List<String>? tags;

  /// ★有料版の余白: 有効期限（今はnull可）
  final DateTime? expiresAt;

  /// [KeyModel] を作成する
  ///
  /// [name] キーの名前
  /// [category] カテゴリ
  /// [type] キーの種類
  /// [value] キーの値
  KeyModel({
    this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.value,
    this.memo,
    this.username,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.expiresAt,
  });

  /// SQLite の Map からインスタンスを生成する
  factory KeyModel.fromMap(Map<String, dynamic> map) {
    return KeyModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      type: map['type'] as String,
      value: map['value'] as String,
      memo: map['memo'] as String?,
      username: map['username'] as String?,
      email: map['email'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      tags: map['tags'] != null
          ? (jsonDecode(map['tags'] as String) as List)
              .cast<String>()
          : null,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    );
  }

  /// SQLite 保存用の Map に変換する
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'type': type,
      'value': value,
      'memo': memo,
      'username': username,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags != null ? jsonEncode(tags) : null,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// 一部のフィールドだけ変更した新しいインスタンスを作成する
  KeyModel copyWith({
    int? id,
    String? name,
    String? category,
    String? type,
    String? value,
    String? memo,
    String? username,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    DateTime? expiresAt,
  }) {
    return KeyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      value: value ?? this.value,
      memo: memo ?? this.memo,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// JSON文字列に変換する（バックアップ用）
  String toJson() => jsonEncode(toMap());

  /// JSON文字列からインスタンスを生成する（復元用）
  factory KeyModel.fromJson(String source) =>
      KeyModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
