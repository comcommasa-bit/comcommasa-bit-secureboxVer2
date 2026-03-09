/// SecureBox 定数・設定管理
///
/// アプリ全体で使用する定数を定義する。
/// カテゴリ、保存数制限、暗号化設定など。
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// アプリ全体の定数
class AppConstants {
  AppConstants._();

  /// アプリ名
  static const String appName = 'パスワード保管庫';

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

  /// デフォルトのキー種類
  static const List<String> keyTypes = [
    'API Key',
    'Password',
    'Secret',
    'Token',
    'その他',
  ];

  /// カスタムカテゴリの保存キー
  static const String _customCategoriesKey = 'custom_categories';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// カスタムカテゴリを読み込む
  static Future<List<String>> getCustomCategories() async {
    final stored = await _storage.read(key: _customCategoriesKey);
    if (stored == null || stored.isEmpty) return [];
    return (jsonDecode(stored) as List).cast<String>();
  }

  /// カスタムカテゴリを保存する
  static Future<void> saveCustomCategories(
    List<String> customCategories,
  ) async {
    await _storage.write(
      key: _customCategoriesKey,
      value: jsonEncode(customCategories),
    );
  }

  /// 全カテゴリを取得する（デフォルト + カスタム）
  static Future<List<String>> getAllCategories() async {
    final custom = await getCustomCategories();
    return [...categories, ...custom];
  }

  /// カスタムカテゴリを追加する
  static Future<void> addCustomCategory(String name) async {
    final custom = await getCustomCategories();
    if (!custom.contains(name) && !categories.contains(name)) {
      custom.add(name);
      await saveCustomCategories(custom);
    }
  }

  /// カスタムカテゴリを削除する
  static Future<void> removeCustomCategory(String name) async {
    final custom = await getCustomCategories();
    custom.remove(name);
    await saveCustomCategories(custom);
  }

  /// カスタムカテゴリのアイコンを取得する
  static IconData getCategoryIcon(String category) {
    return categoryIcons[category] ?? Icons.label;
  }

  /// ★有料版の余白: プラン判定（今は常にfalse）
  static bool get isPro => false;

  /// ★有料版の余白: 保存数上限を返す
  static int get maxItems => isPro ? -1 : freePlanLimit;
}
