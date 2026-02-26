import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'crypto_service.dart';

/// 認証サービス
///
/// マスターパスワード管理と生体認証（指紋・顔認証）を提供する
class AuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // SecureStorage キー名
  static const String _keyPasswordHash = 'master_password_hash';
  static const String _keyPasswordSalt = 'master_password_salt';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  // --- マスターパスワード管理 ---

  /// マスターパスワードが設定済みか確認
  static Future<bool> isPasswordSet() async {
    final hash = await _secureStorage.read(key: _keyPasswordHash);
    return hash != null;
  }

  /// マスターパスワードを設定（初回セットアップ）
  ///
  /// パスワードそのものは保存しない。ハッシュとソルトのみ保存。
  /// PBKDF2はIsolateで実行しUIをブロックしない
  static Future<void> setMasterPassword(String password) async {
    final salt = CryptoService.generateSalt();
    final hash = await CryptoService.hashPasswordAsync(password, salt);

    await _secureStorage.write(key: _keyPasswordHash, value: hash);
    await _secureStorage.write(
      key: _keyPasswordSalt,
      value: base64Encode(salt),
    );
  }

  /// マスターパスワードを検証
  ///
  /// PBKDF2はIsolateで実行しUIをブロックしない
  static Future<bool> verifyMasterPassword(String password) async {
    final storedHash = await _secureStorage.read(key: _keyPasswordHash);
    final storedSaltBase64 = await _secureStorage.read(key: _keyPasswordSalt);

    if (storedHash == null || storedSaltBase64 == null) return false;

    final salt = base64Decode(storedSaltBase64);
    return CryptoService.verifyPasswordAsync(
      password,
      storedHash,
      salt,
    );
  }

  /// マスターパスワードを変更
  ///
  /// 旧パスワードの検証後に新パスワードを設定
  static Future<bool> changeMasterPassword(
    String oldPassword,
    String newPassword,
  ) async {
    final isValid = await verifyMasterPassword(oldPassword);
    if (!isValid) return false;

    await setMasterPassword(newPassword);
    return true;
  }

  // --- 生体認証 ---

  /// デバイスが生体認証に対応しているか確認
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// 利用可能な生体認証の種類を取得
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// 生体認証を実行
  ///
  /// 成功時にtrue、失敗またはキャンセル時にfalseを返す
  static Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'SecureBoxのロックを解除',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// 生体認証の有効/無効を設定
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// 生体認証が有効か確認
  static Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // --- ユーティリティ ---

  /// 認証データをすべて削除（アプリリセット用）
  static Future<void> clearAll() async {
    await _secureStorage.delete(key: _keyPasswordHash);
    await _secureStorage.delete(key: _keyPasswordSalt);
    await _secureStorage.delete(key: _keyBiometricEnabled);
  }
}
