import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/services/crypto_service.dart';

void main() {
  const testPassword = 'TestPassword123!';
  const testPlainText = 'Hello SecureBox! これはテストです。';

  group('ソルト・IV生成', () {
    test('generateSaltは16バイトを返す', () {
      final salt = CryptoService.generateSalt();
      expect(salt.length, 16);
    });

    test('generateIvは16バイトを返す', () {
      final iv = CryptoService.generateIv();
      expect(iv.length, 16);
    });

    test('generateSaltは毎回異なる値を返す', () {
      final salt1 = CryptoService.generateSalt();
      final salt2 = CryptoService.generateSalt();
      expect(salt1, isNot(equals(salt2)));
    });
  });

  group('鍵導出（PBKDF2）', () {
    test('同じパスワード・ソルトから同じキーが導出される', () {
      final salt = CryptoService.generateSalt();
      final key1 = CryptoService.deriveKey(testPassword, salt);
      final key2 = CryptoService.deriveKey(testPassword, salt);

      expect(key1, equals(key2));
    });

    test('導出されるキーは32バイト（256bit）', () {
      final salt = CryptoService.generateSalt();
      final key = CryptoService.deriveKey(testPassword, salt);

      expect(key.length, 32);
    });

    test('異なるソルトからは異なるキーが導出される', () {
      final salt1 = CryptoService.generateSalt();
      final salt2 = CryptoService.generateSalt();
      final key1 = CryptoService.deriveKey(testPassword, salt1);
      final key2 = CryptoService.deriveKey(testPassword, salt2);

      expect(key1, isNot(equals(key2)));
    });

    test('異なるパスワードからは異なるキーが導出される', () {
      final salt = CryptoService.generateSalt();
      final key1 = CryptoService.deriveKey('password1', salt);
      final key2 = CryptoService.deriveKey('password2', salt);

      expect(key1, isNot(equals(key2)));
    });
  });

  group('暗号化・復号', () {
    test('暗号化して復号すると元のテキストに戻る', () {
      final encrypted = CryptoService.encryptText(
        testPlainText,
        testPassword,
      );
      final decrypted = CryptoService.decryptText(
        encrypted,
        testPassword,
      );

      expect(decrypted, testPlainText);
    });

    test('暗号化結果は "salt:iv:data" 形式', () {
      final encrypted = CryptoService.encryptText(
        testPlainText,
        testPassword,
      );
      final parts = encrypted.split(':');

      expect(parts.length, 3);
      // 各パートがBase64文字列であること
      for (final part in parts) {
        expect(part.isNotEmpty, isTrue);
      }
    });

    test('同じ平文でも毎回異なる暗号文が生成される', () {
      final encrypted1 = CryptoService.encryptText(
        testPlainText,
        testPassword,
      );
      final encrypted2 = CryptoService.encryptText(
        testPlainText,
        testPassword,
      );

      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('間違ったパスワードでは復号に失敗する', () {
      final encrypted = CryptoService.encryptText(
        testPlainText,
        testPassword,
      );

      expect(
        () => CryptoService.decryptText(encrypted, 'WrongPassword!'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('不正な形式の文字列は FormatException を投げる', () {
      expect(
        () => CryptoService.decryptText('invalid', testPassword),
        throwsA(isA<FormatException>()),
      );
    });

    test('日本語を暗号化・復号できる', () {
      const japanese = 'パスワード保管庫テスト🔐';
      final encrypted = CryptoService.encryptText(
        japanese,
        testPassword,
      );
      final decrypted = CryptoService.decryptText(
        encrypted,
        testPassword,
      );

      expect(decrypted, japanese);
    });

    test('長い文字列を暗号化・復号できる', () {
      final longText = 'A' * 10000;
      final encrypted = CryptoService.encryptText(
        longText,
        testPassword,
      );
      final decrypted = CryptoService.decryptText(
        encrypted,
        testPassword,
      );

      expect(decrypted, longText);
    });
  });

  group('パスワードハッシュ・検証', () {
    test('同じパスワード・ソルトから同じハッシュが生成される', () {
      final salt = CryptoService.generateSalt();
      final hash1 = CryptoService.hashPassword(testPassword, salt);
      final hash2 = CryptoService.hashPassword(testPassword, salt);

      expect(hash1, hash2);
    });

    test('正しいパスワードで検証が成功する', () {
      final salt = CryptoService.generateSalt();
      final hash = CryptoService.hashPassword(testPassword, salt);

      final result = CryptoService.verifyPassword(
        testPassword,
        hash,
        salt,
      );
      expect(result, isTrue);
    });

    test('間違ったパスワードで検証が失敗する', () {
      final salt = CryptoService.generateSalt();
      final hash = CryptoService.hashPassword(testPassword, salt);

      final result = CryptoService.verifyPassword(
        'WrongPassword!',
        hash,
        salt,
      );
      expect(result, isFalse);
    });
  });
}
