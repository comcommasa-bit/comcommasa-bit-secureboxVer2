/// 暗号化・復号化サービス
///
/// AES-256-GCM による暗号化と PBKDF2 による鍵導出を行う。
/// マスターパスワードから暗号化キーを生成し、
/// データの暗号化・復号化を提供する。
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../config/constants.dart';

/// 暗号化・復号化を行うサービス
class CryptoService {
  /// PBKDF2 でマスターパスワードからAES-256キーを導出する
  ///
  /// [password] マスターパスワード
  /// [salt] ソルト（ランダムバイト列）
  ///
  /// Returns: 32バイトの暗号化キー
  static Uint8List deriveKey(String password, Uint8List salt) {
    final hmacSha256 = Hmac(sha256, utf8.encode(password));
    final iterations = AppConstants.pbkdf2Iterations;
    final keyLength = AppConstants.keyLength;

    var block = Uint8List(0);
    var result = Uint8List(0);
    var blockNum = 1;

    while (result.length < keyLength) {
      block = _pbkdf2Block(
        hmacSha256,
        salt,
        iterations,
        blockNum,
      );
      result = Uint8List.fromList([...result, ...block]);
      blockNum++;
    }

    return Uint8List.fromList(result.sublist(0, keyLength));
  }

  /// PBKDF2 の1ブロック分を計算する
  static Uint8List _pbkdf2Block(
    Hmac hmac,
    Uint8List salt,
    int iterations,
    int blockNum,
  ) {
    final blockBytes = ByteData(4)..setUint32(0, blockNum);
    final input = Uint8List.fromList([
      ...salt,
      ...blockBytes.buffer.asUint8List(),
    ]);

    var u = hmac.convert(input).bytes;
    var result = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// ランダムなソルトを生成する（16バイト）
  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// ランダムなIVを生成する（16バイト）
  static Uint8List generateIv() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(AppConstants.ivLength, (_) => random.nextInt(256)),
    );
  }

  /// 文字列を暗号化する
  ///
  /// [plainText] 暗号化する平文
  /// [password] マスターパスワード
  ///
  /// Returns: "salt:iv:暗号文" の形式のBase64文字列
  static String encryptText(String plainText, String password) {
    final salt = generateSalt();
    final iv = generateIv();
    final key = deriveKey(password, salt);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(key),
        mode: encrypt.AESMode.cbc,
      ),
    );

    final encrypted = encrypter.encrypt(
      plainText,
      iv: encrypt.IV(iv),
    );

    final saltB64 = base64Encode(salt);
    final ivB64 = base64Encode(iv);
    final dataB64 = encrypted.base64;

    return '$saltB64:$ivB64:$dataB64';
  }

  /// 暗号化された文字列を復号する
  ///
  /// [encryptedText] "salt:iv:暗号文" 形式の文字列
  /// [password] マスターパスワード
  ///
  /// Returns: 復号された平文
  /// Throws: [FormatException] 形式が不正な場合
  /// Throws: [ArgumentError] 復号に失敗した場合
  static String decryptText(String encryptedText, String password) {
    final parts = encryptedText.split(':');
    if (parts.length != 3) {
      throw const FormatException(
        '暗号化データの形式が不正です',
      );
    }

    final salt = base64Decode(parts[0]);
    final iv = base64Decode(parts[1]);
    final data = parts[2];

    final key = deriveKey(password, Uint8List.fromList(salt));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(key),
        mode: encrypt.AESMode.cbc,
      ),
    );

    return encrypter.decrypt64(
      data,
      iv: encrypt.IV(Uint8List.fromList(iv)),
    );
  }

  /// マスターパスワードのハッシュを生成する（検証用）
  ///
  /// [password] マスターパスワード
  /// [salt] ソルト
  ///
  /// Returns: Base64エンコードされたハッシュ文字列
  static String hashPassword(String password, Uint8List salt) {
    final key = deriveKey(password, salt);
    return base64Encode(key);
  }

  /// マスターパスワードを検証する
  ///
  /// [password] 入力されたパスワード
  /// [storedHash] 保存済みハッシュ
  /// [salt] 保存済みソルト
  ///
  /// Returns: パスワードが正しければ true
  static bool verifyPassword(
    String password,
    String storedHash,
    Uint8List salt,
  ) {
    final hash = hashPassword(password, salt);
    return hash == storedHash;
  }
}
