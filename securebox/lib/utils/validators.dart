/// 入力バリデーションユーティリティ
class Validators {
  Validators._();

  /// 必須フィールドのバリデーション
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldNameは必須です';
    }
    return null;
  }

  /// マスターパスワードのバリデーション
  ///
  /// 8文字以上必須
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードは必須です';
    }
    if (value.length < 8) {
      return 'パスワードは8文字以上必要です';
    }
    return null;
  }

  /// パスワード確認のバリデーション
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'パスワード確認は必須です';
    }
    if (value != password) {
      return 'パスワードが一致しません';
    }
    return null;
  }

  /// キー名のバリデーション
  static String? validateKeyName(String? value) {
    return validateRequired(value, 'キー名');
  }

  /// キー値のバリデーション
  static String? validateKeyValue(String? value) {
    return validateRequired(value, 'キー値');
  }
}
