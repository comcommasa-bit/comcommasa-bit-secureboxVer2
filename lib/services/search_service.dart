/// 検索サービス
///
/// キーリストのフィルタリング機能を提供する。
library;

import '../models/key_model.dart';

/// キーワード検索・フィルタリングサービス
class SearchService {
  SearchService._();

  /// キーのリストをキーワードでフィルタリングする
  ///
  /// name, category, type, memo を対象に
  /// 部分一致（大文字小文字区別なし）で検索する。
  ///
  /// [keys] 検索対象のキーリスト
  /// [query] 検索キーワード
  ///
  /// Returns: フィルタリングされたキーリスト
  static List<KeyModel> filterKeys(
    List<KeyModel> keys,
    String query,
  ) {
    if (query.trim().isEmpty) return keys;

    final q = query.toLowerCase();

    return keys.where((key) {
      return key.name.toLowerCase().contains(q) ||
          key.category.toLowerCase().contains(q) ||
          key.type.toLowerCase().contains(q) ||
          (key.memo?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// カテゴリでフィルタリングする
  ///
  /// [keys] 対象のキーリスト
  /// [category] カテゴリ名
  ///
  /// Returns: 該当カテゴリのキーリスト
  static List<KeyModel> filterByCategory(
    List<KeyModel> keys,
    String category,
  ) {
    return keys
        .where((key) => key.category == category)
        .toList();
  }

  /// ★有料版の余白: タグでフィルタリング
  // static List<KeyModel> filterByTags(
  //   List<KeyModel> keys,
  //   List<String> tags,
  // ) {
  //   // 有料版で実装
  // }
}
