/// キーデータのモデルクラス
///
/// パスワードやAPIキーなど、保管するデータの構造を定義
class KeyModel {
  /// データベースID（新規作成時はnull）
  final int? id;

  /// キーの名前（例: "AWS本番アカウント"）
  final String name;

  /// ふりがな（検索用）
  final String? furigana;

  /// カテゴリ（stripe, aws, openai, google, github, other）
  final String category;

  /// キーの種類（api_key, password, secret, token, other）
  final String type;

  /// キーの値（暗号化前の平文 or 暗号化済みテキスト）
  final String value;

  /// メモ
  final String? memo;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime? updatedAt;

  KeyModel({
    this.id,
    required this.name,
    this.furigana,
    required this.category,
    required this.type,
    required this.value,
    this.memo,
    required this.createdAt,
    this.updatedAt,
  });

  /// JSONからKeyModelを生成
  factory KeyModel.fromJson(Map<String, dynamic> json) {
    return KeyModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      furigana: json['furigana'] as String?,
      category: json['category'] as String,
      type: json['type'] as String,
      value: json['value'] as String,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// KeyModelをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'furigana': furigana,
      'category': category,
      'type': type,
      'value': value,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// SQLite保存用のMap（idを除く）
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'furigana': furigana,
      'category': category,
      'type': type,
      'value': value,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// SQLiteの行からKeyModelを生成
  factory KeyModel.fromMap(Map<String, dynamic> map) {
    return KeyModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      furigana: map['furigana'] as String?,
      category: map['category'] as String,
      type: map['type'] as String,
      value: map['value'] as String,
      memo: map['memo'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// フィールドを部分的に更新した新しいインスタンスを返す
  KeyModel copyWith({
    int? id,
    String? name,
    String? furigana,
    String? category,
    String? type,
    String? value,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KeyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      furigana: furigana ?? this.furigana,
      category: category ?? this.category,
      type: type ?? this.type,
      value: value ?? this.value,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'KeyModel(id: $id, name: $name, category: $category, type: $type)';
  }
}
