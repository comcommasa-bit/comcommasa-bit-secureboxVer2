/// アプリ全体で使用する定数・設定値
class Constants {
  Constants._();

  /// カテゴリ識別子リスト
  static const List<String> categories = [
    'stripe',
    'aws',
    'openai',
    'google',
    'github',
    'other',
  ];

  /// カテゴリ表示名マッピング
  static const Map<String, String> categoryNames = {
    'stripe': 'Stripe',
    'aws': 'AWS',
    'openai': 'OpenAI',
    'google': 'Google',
    'github': 'GitHub',
    'other': 'その他',
  };

  /// キーの種類
  static const List<String> keyTypes = [
    'api_key',
    'password',
    'secret',
    'token',
    'other',
  ];

  /// キーの種類 表示名マッピング
  static const Map<String, String> keyTypeNames = {
    'api_key': 'APIキー',
    'password': 'パスワード',
    'secret': 'シークレット',
    'token': 'トークン',
    'other': 'その他',
  };

  /// 無料版の最大保存数
  static const int maxFreeKeys = 10;

  /// PBKDF2 イテレーション回数
  static const int pbkdf2Iterations = 600000;

  /// AES鍵長（ビット）
  static const int aesKeyLength = 256;

  /// AES IV長（バイト）
  static const int aesIvLength = 16;

  /// ソルト長（バイト）
  static const int saltLength = 32;

  /// バックエンドURL
  static const String backendUrl = 'https://your-domain.vercel.app';

  /// データベース名
  static const String dbName = 'securebox.db';

  /// データベースバージョン
  static const int dbVersion = 1;

  /// Stripe月額料金（円）
  static const int monthlyPrice = 980;
}
