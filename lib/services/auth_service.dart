/// 認証サービス
///
/// 生体認証（指紋・顔）とマスターパスワード管理を提供する。
/// マスターパスワードのハッシュとソルトは flutter_secure_storage で
/// 安全に保存される。
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'crypto_service.dart';

/// 認証を管理するサービスクラス（シングルトン）
class AuthService {
  // シングルトンパターン
  static final AuthService _instance = AuthService._internal();

  /// シングルトンインスタンスを取得する
  factory AuthService() => _instance;

  AuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  // SecureStorage のキー名
  static const _keyPasswordHash = 'master_password_hash';
  static const _keySalt = 'master_password_salt';
  static const _keyBiometricsEnabled = 'biometrics_enabled';

  // ─── マスターパスワード管理 ───

  /// マスターパスワードが設定済みか確認する
  ///
  /// Returns: 設定済みなら true（初回起動判定に使用）
  Future<bool> get isPasswordSet async {
    final hash = await _secureStorage.read(key: _keyPasswordHash);
    return hash != null;
  }

  /// マスターパスワードを保存する（初回設定時）
  ///
  /// [password] 設定するマスターパスワード
  Future<void> savePassword(String password) async {
    final salt = CryptoService.generateSalt();
    final hash = CryptoService.hashPassword(password, salt);

    await _secureStorage.write(
      key: _keyPasswordHash,
      value: hash,
    );
    await _secureStorage.write(
      key: _keySalt,
      value: base64Encode(salt),
    );
  }

  /// マスターパスワードを検証する
  ///
  /// [password] 入力されたパスワード
  ///
  /// Returns: パスワードが正しければ true
  Future<bool> verifyPassword(String password) async {
    final storedHash = await _secureStorage.read(
      key: _keyPasswordHash,
    );
    final saltB64 = await _secureStorage.read(key: _keySalt);

    if (storedHash == null || saltB64 == null) return false;

    final salt = base64Decode(saltB64);
    return CryptoService.verifyPassword(
      password,
      storedHash,
      Uint8List.fromList(salt),
    );
  }

  /// 保存済みのソルトを取得する（暗号化/復号で使用）
  ///
  /// Returns: ソルト（未設定時は null）
  Future<Uint8List?> getSalt() async {
    final saltB64 = await _secureStorage.read(key: _keySalt);
    if (saltB64 == null) return null;
    return Uint8List.fromList(base64Decode(saltB64));
  }

  // ─── 生体認証 ───

  /// 生体認証が利用可能か確認する
  ///
  /// Returns: 利用可能な場合は true
  Future<bool> get isBiometricsAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// 利用可能な生体認証の種類を取得する
  ///
  /// Returns: 利用可能な BiometricType のリスト
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  /// 生体認証を実行する
  ///
  /// [reason] 認証を求める理由（ユーザーに表示される）
  ///
  /// Returns: 認証成功時は true
  Future<bool> authenticateBiometric({
    String reason = 'SecureBoxのロックを解除',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// 生体認証の有効/無効設定を保存する
  ///
  /// [enabled] 有効にする場合は true
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricsEnabled,
      value: enabled.toString(),
    );
  }

  /// 生体認証が有効かどうかを取得する
  ///
  /// Returns: 有効なら true
  Future<bool> get isBiometricsEnabled async {
    final value = await _secureStorage.read(
      key: _keyBiometricsEnabled,
    );
    return value == 'true';
  }

  // ─── リセット ───

  /// 全認証データを削除する（リセット用）
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _keyPasswordHash);
    await _secureStorage.delete(key: _keySalt);
    await _secureStorage.delete(key: _keyBiometricsEnabled);
  }
}
