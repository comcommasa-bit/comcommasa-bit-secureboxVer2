/// ヘルパー関数
///
/// 日付フォーマットや文字列マスクなど、
/// アプリ全体で使う汎用ユーティリティ。
library;

/// ヘルパー関数群
class Helpers {
  Helpers._();

  /// 日付を表示用にフォーマットする
  ///
  /// [date] フォーマットする日時
  ///
  /// Returns: "2024/03/04 14:30" 形式の文字列
  static String formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $h:$min';
  }

  /// 日付を日付のみでフォーマットする
  ///
  /// [date] フォーマットする日時
  ///
  /// Returns: "2024/03/04" 形式の文字列
  static String formatDateOnly(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  /// 文字列をマスクする
  ///
  /// APIキーなどの機密情報を部分的に隠す。
  /// 例: "sk_test_abc123" → "sk_test_***"
  ///
  /// [text] マスクする文字列
  /// [visibleChars] 先頭から表示する文字数（デフォルト: 8）
  ///
  /// Returns: マスクされた文字列
  static String maskText(String text, {int visibleChars = 8}) {
    if (text.length <= visibleChars) {
      return '*' * text.length;
    }
    final visible = text.substring(0, visibleChars);
    return '$visible${'*' * (text.length - visibleChars)}';
  }

  /// 文字列を切り詰める
  ///
  /// [text] 切り詰める文字列
  /// [maxLength] 最大文字数（デフォルト: 30）
  ///
  /// Returns: 切り詰められた文字列（"..."付き）
  static String truncate(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
