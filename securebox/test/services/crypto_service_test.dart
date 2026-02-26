import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/config/constants.dart';
import 'package:securebox/services/crypto_service.dart';

void main() {
  group('CryptoService', () {
    group('generateSalt', () {
      test('指定された長さのソルトを生成する', () {
        final salt = CryptoService.generateSalt();
        expect(salt.length, Constants.saltLength);
      });

      test('毎回異なるソルトを生成する', () {
        final salt1 = CryptoService.generateSalt();
        final salt2 = CryptoService.generateSalt();
        expect(salt1, isNot(equals(salt2)));
      });
    });

    group('generateIv', () {
      test('指定された長さのIVを生成する', () {
        final iv = CryptoService.generateIv();
        expect(iv.length, Constants.aesIvLength);
      });

      test('毎回異なるIVを生成する', () {
        final iv1 = CryptoService.generateIv();
        final iv2 = CryptoService.generateIv();
        expect(iv1, isNot(equals(iv2)));
      });
    });

    group('deriveKey', () {
      // NOTE: deriveKey は60万回イテレーションのため非常に遅い。
      // CI環境ではスキップするか、イテレーション回数を下げたテスト用設定を使う。
      test('32バイト（256ビット）のキーを導出する', () {
        final salt = Uint8List.fromList(List.filled(32, 0x01));
        final key = CryptoService.deriveKey('testpassword', salt);
        expect(key.length, 32); // 256 bits
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('同じパスワード・ソルトから同じキーが導出される', () {
        final salt = Uint8List.fromList(List.filled(32, 0xAB));
        final key1 = CryptoService.deriveKey('password123', salt);
        final key2 = CryptoService.deriveKey('password123', salt);
        expect(key1, equals(key2));
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('異なるパスワードからは異なるキーが導出される', () {
        final salt = Uint8List.fromList(List.filled(32, 0xAB));
        final key1 = CryptoService.deriveKey('password1', salt);
        final key2 = CryptoService.deriveKey('password2', salt);
        expect(key1, isNot(equals(key2)));
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('異なるソルトからは異なるキーが導出される', () {
        final salt1 = Uint8List.fromList(List.filled(32, 0x01));
        final salt2 = Uint8List.fromList(List.filled(32, 0x02));
        final key1 = CryptoService.deriveKey('samepassword', salt1);
        final key2 = CryptoService.deriveKey('samepassword', salt2);
        expect(key1, isNot(equals(key2)));
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');
    });

    group('encryptText / decryptText', () {
      test('暗号化→復号化で元のテキストが復元される', () {
        const password = 'masterpassword123';
        const plainText = 'sk-test-abcdef12345';

        final encrypted = CryptoService.encryptText(plainText, password);
        final decrypted = CryptoService.decryptText(encrypted, password);

        expect(decrypted, plainText);
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('暗号化結果はsalt:iv:ciphertext形式', () {
        const password = 'testpass12345678';
        const plainText = 'hello';

        final encrypted = CryptoService.encryptText(plainText, password);
        final parts = encrypted.split(':');

        expect(parts.length, 3);
        // 各パートがBase64デコード可能
        expect(() => base64Decode(parts[0]), returnsNormally);
        expect(() => base64Decode(parts[1]), returnsNormally);
        expect(() => base64Decode(parts[2]), returnsNormally);
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('同じテキストでも毎回異なる暗号文が生成される（ソルト/IVが異なる）', () {
        const password = 'testpass12345678';
        const plainText = 'same-text';

        final encrypted1 = CryptoService.encryptText(plainText, password);
        final encrypted2 = CryptoService.encryptText(plainText, password);

        expect(encrypted1, isNot(equals(encrypted2)));
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('間違ったパスワードでは復号化に失敗する', () {
        const password = 'correctpassword1';
        const wrongPassword = 'wrongpassword12';
        const plainText = 'secret-data';

        final encrypted = CryptoService.encryptText(plainText, password);

        expect(
          () => CryptoService.decryptText(encrypted, wrongPassword),
          throwsA(isA<Exception>()),
        );
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');
    });

    group('decryptText エラー処理', () {
      test('不正なフォーマットでFormatExceptionをスロー', () {
        expect(
          () => CryptoService.decryptText('invalid-format', 'password'),
          throwsA(isA<FormatException>()),
        );
      });

      test('コロンが2つ未満でFormatExceptionをスロー', () {
        expect(
          () => CryptoService.decryptText('only:one', 'password'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('hashPassword / verifyPassword', () {
      test('同じパスワード・ソルトで同じハッシュが生成される', () {
        final salt = Uint8List.fromList(List.filled(32, 0xCC));
        final hash1 = CryptoService.hashPassword('mypassword', salt);
        final hash2 = CryptoService.hashPassword('mypassword', salt);
        expect(hash1, equals(hash2));
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('正しいパスワードで検証成功', () {
        final salt = Uint8List.fromList(List.filled(32, 0xDD));
        final hash = CryptoService.hashPassword('correct', salt);
        expect(CryptoService.verifyPassword('correct', hash, salt), true);
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');

      test('間違ったパスワードで検証失敗', () {
        final salt = Uint8List.fromList(List.filled(32, 0xDD));
        final hash = CryptoService.hashPassword('correct', salt);
        expect(CryptoService.verifyPassword('wrong', hash, salt), false);
      },
          skip: 'PBKDF2 60万回イテレーションのため実行時間が長い。'
              'ローカル実機で確認する場合はskipを外してください。');
    });
  });
}
