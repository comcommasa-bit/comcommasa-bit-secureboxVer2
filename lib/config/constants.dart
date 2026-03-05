/// SecureBox 定数・設定管理
///
/// アプリ全体で使用する定数を定義する。
/// カテゴリ、保存数制限、暗号化設定など。
library;

import 'package:flutter/material.dart';

/// アプリ全体の定数
class AppConstants {
  AppConstants._();

  /// アプリ名
  static const String appName = 'SecureBox';

  /// 無料版の保存数制限
  static const int freePlanLimit = 10;

  /// 暗号化設定: PBKDF2イテレーション回数（60万回）
  static const int pbkdf2Iterations = 600000;

  /// 暗号化設定: AES-256キー長（32バイト）
  static const int keyLength = 32;

  /// 暗号化設定: AES IVサイズ（16バイト）
  static const int ivLength = 16;

  /// カテゴリ定義（6種類）
  static const List<String> categories = [
    'Stripe',
    'AWS',
    'OpenAI',
    'Google',
    'GitHub',
    'その他',
  ];

  /// カテゴリごとのアイコン
  static const Map<String, IconData> categoryIcons = {
    'Stripe': Icons.payment,
    'AWS': Icons.cloud,
    'OpenAI': Icons.smart_toy,
    'Google': Icons.g_mobiledata,
    'GitHub': Icons.code,
    'その他': Icons.more_horiz,
  };

  /// UI: デフォルトパディング
  static const double defaultPadding = 16.0;

  /// UI: デフォルト角丸
  static const double defaultRadius = 8.0;

  /// ★有料版の余白: プラン判定（今は常にfalse）
  static bool get isPro => false;

  /// ★有料版の余白: 保存数上限を返す
  static int get maxItems => isPro ? -1 : freePlanLimit;
}
