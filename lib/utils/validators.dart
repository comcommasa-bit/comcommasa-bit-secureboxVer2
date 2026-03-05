/// バリデーション
///
/// 入力値の検証ロジックを提供する。
library;

class Validators {
  Validators._(); // インスタンス化を防止

  /// 空でないことを検証する
  ///
  /// [value] 検証する文字列
  /// [message] エラーメッセージ（任意）
  ///
  /// Returns: エラーメッセージ（無効な場合）、null（有効な場合）
  static String? notEmpty(String? value, {String message = 'この項目は必須です'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// マスターパスワードの要件を検証する
  ///
  /// - 8文字以上
  ///
  /// [value] 検証するパスワード
  ///
  /// Returns: エラーメッセージ（無効な場合）、null（有効な場合）
  static String? masterPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < 8) {
      return '8文字以上で入力してください';
    }
    // TODO: より複雑な要件（大文字、小文字、数字、記号の混在など）を追加することも可能
    return null;
  }

  /// ★有料版の余白: パスワード強度を評価する
  ///
  /// [password] 評価するパスワード
  ///
  /// Returns: 強度スコア (0.0 - 1.0)
  static double getPasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double score = 0.0;

    // 1. 長さ (スコアの40%を占める)
    score += password.length > 12 ? 0.4 : password.length / 30.0;

    // 2. 文字種 (それぞれ15%)
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score += 0.15;

    // スコアが1.0を超えないようにする
    return score > 1.0 ? 1.0 : score;
  }
}