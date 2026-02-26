import 'package:intl/intl.dart';

/// 汎用ヘルパー関数
class Helpers {
  Helpers._();

  /// 日付を yyyy/MM/dd 形式にフォーマット
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// 日時を yyyy/MM/dd HH:mm 形式にフォーマット
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  /// キー値をマスク表示用にする（先頭4文字 + ****）
  static String maskValue(String value) {
    if (value.length <= 4) {
      return '****';
    }
    return '${value.substring(0, 4)}${'*' * (value.length - 4).clamp(0, 12)}';
  }

  /// クリップボードにコピー後の自動クリア用の遅延（秒）
  static const int clipboardClearDelay = 30;
}
