import '../models/key_model.dart';

/// 検索サービス
///
/// キーワード検索・カテゴリフィルタリングを提供する
class SearchService {
  SearchService._();

  /// キーワードでキーを検索
  ///
  /// 名前、ふりがな、メモを対象に部分一致検索
  static List<KeyModel> searchByKeyword(
      List<KeyModel> keys, String keyword) {
    if (keyword.trim().isEmpty) return keys;

    final lowerKeyword = keyword.toLowerCase();
    return keys.where((key) {
      return key.name.toLowerCase().contains(lowerKeyword) ||
          (key.furigana?.toLowerCase().contains(lowerKeyword) ?? false) ||
          (key.memo?.toLowerCase().contains(lowerKeyword) ?? false);
    }).toList();
  }

  /// カテゴリでフィルタリング
  static List<KeyModel> filterByCategory(
      List<KeyModel> keys, String category) {
    if (category.isEmpty || category == 'all') return keys;
    return keys.where((key) => key.category == category).toList();
  }

  /// キーワード + カテゴリの複合検索
  static List<KeyModel> search(
    List<KeyModel> keys, {
    String keyword = '',
    String category = '',
  }) {
    var result = keys;
    result = filterByCategory(result, category);
    result = searchByKeyword(result, keyword);
    return result;
  }
}
