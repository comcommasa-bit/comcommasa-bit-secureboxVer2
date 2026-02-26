import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../config/constants.dart';

/// 暗号化・復号化サービス
///
/// AES-256-GCM + PBKDF2鍵導出を使用してデータを暗号化・復号化する
class CryptoService {
  /// マスターパスワードからAES暗号化キーを導出する
  ///
  /// PBKDF2-HMAC-SHA256を使用、60万回イテレーション
  static Uint8List deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    final hmacSha256 = Hmac(sha256, passwordBytes);

    // PBKDF2実装
    final blockCount = (Constants.aesKeyLength ~/ 8 + sha256.blockSize - 1) ~/
        sha256.blockSize;
    final derivedKey = Uint8List(blockCount * sha256.blockSize);

    for (var block = 1; block <= blockCount; block++) {
      final blockBytes = Uint8List(4);
      blockBytes[0] = (block >> 24) & 0xff;
      blockBytes[1] = (block >> 16) & 0xff;
      blockBytes[2] = (block >> 8) & 0xff;
      blockBytes[3] = block & 0xff;

      var u = hmacSha256
          .convert(Uint8List.fromList([...salt, ...blockBytes])).bytes;
      var result = Uint8List.fromList(u);

      for (var i = 1; i < Constants.pbkdf2Iterations; i++) {
        u = hmacSha256.convert(u).bytes;
        for (var j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }

      derivedKey.setRange(
        (block - 1) * sha256.blockSize,
        (block - 1) * sha256.blockSize + result.length,
        result,
      );
    }

    return Uint8List.fromList(
        derivedKey.sublist(0, Constants.aesKeyLength ~/ 8));
  }

  /// ランダムなソルトを生成
  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(Constants.saltLength, (_) => random.nextInt(256)),
    );
  }

  /// ランダムなIVを生成
  static Uint8List generateIv() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(Constants.aesIvLength, (_) => random.nextInt(256)),
    );
  }

  /// テキストを暗号化する
  ///
  /// 返り値: "salt:iv:暗号文" のBase64エンコード文字列
  static String encryptText(String plainText, String password) {
    final salt = generateSalt();
    final iv = generateIv();
    final key = deriveKey(password, salt);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(key),
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );

    final encrypted = encrypter.encrypt(
      plainText,
      iv: encrypt.IV(iv),
    );

    // salt:iv:暗号文 をBase64で結合
    final combined = '${base64Encode(salt)}:${base64Encode(iv)}:${encrypted.base64}';
    return combined;
  }

  /// 暗号文を復号化する
  ///
  /// [encryptedText] "salt:iv:暗号文" 形式のBase64文字列
  static String decryptText(String encryptedText, String password) {
    final parts = encryptedText.split(':');
    if (parts.length != 3) {
      throw const FormatException('Invalid encrypted text format');
    }

    final salt = Uint8List.fromList(base64Decode(parts[0]));
    final iv = Uint8List.fromList(base64Decode(parts[1]));
    final cipherText = parts[2];

    final key = deriveKey(password, salt);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(key),
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );

    return encrypter.decrypt64(
      cipherText,
      iv: encrypt.IV(iv),
    );
  }

  /// マスターパスワードのハッシュを生成（検証用）
  ///
  /// パスワードそのものは保存せず、ハッシュのみ保存して検証に使う
  static String hashPassword(String password, Uint8List salt) {
    final key = deriveKey(password, salt);
    return base64Encode(key);
  }

  /// マスターパスワードを検証
  static bool verifyPassword(
      String password, String storedHash, Uint8List salt) {
    final hash = hashPassword(password, salt);
    return hash == storedHash;
  }
}
