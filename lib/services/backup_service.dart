/// バックアップサービス
///
/// ローカルファイルおよびGoogle Driveへのバックアップ機能を提供する。
/// バックアップデータはマスターパスワードで全体が暗号化される。
/// ファイル形式: .sbx（SecureBox独自形式）
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import 'crypto_service.dart';
import 'storage_service.dart';

/// バックアップ・復元を行うサービス（シングルトン）
class BackupService {
  // シングルトンパターン
  static final BackupService _instance = BackupService._internal();

  /// シングルトンインスタンスを取得する
  factory BackupService() => _instance;

  BackupService._internal();

  // ─── ローカルバックアップ（無料版） ───

  /// ローカルファイルへエクスポートする
  ///
  /// 全データをJSON化し、マスターパスワードで暗号化して
  /// .sbx ファイルとして保存する。
  ///
  /// [password] 暗号化に使用するマスターパスワード
  ///
  /// Returns: 保存されたファイルのパス（キャンセル時は null）
  /// Throws: [Exception] データが空の場合
  Future<String?> exportToLocalFile(String password) async {
    final keys = await StorageService().getAllKeys();
    if (keys.isEmpty) {
      throw Exception('エクスポートするデータがありません');
    }

    // JSON化 → 全体暗号化（メタデータも保護）
    final jsonList = keys.map((k) => k.toMap()).toList();
    final jsonString = jsonEncode(jsonList);
    final encryptedData = CryptoService.encryptText(
      jsonString,
      password,
    );

    // ファイル名生成（例: securebox_20260304.sbx）
    final now = DateTime.now();
    final dateStr = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final fileName = 'securebox_$dateStr.sbx';

    // ファイル保存ダイアログ
    return FilePicker.platform.saveFile(
      dialogTitle: 'バックアップファイルを保存',
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(encryptedData)),
    );
  }

  /// ローカルファイルからインポートする
  ///
  /// .sbx ファイルを読み込み、復号してデータベースに追加する。
  /// IDは除外し、新規データとして追加される（既存データとの競合回避）。
  /// 元のタイムスタンプは保持される。
  ///
  /// [password] 復号に使用するマスターパスワード
  ///
  /// Returns: ({int imported, int skipped}) 復元件数とスキップ件数
  /// Throws: [Exception] 復号失敗時
  Future<({int imported, int skipped})> importFromLocalFile(
    String password,
  ) async {
    // ファイル選択
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) {
      return (imported: 0, skipped: 0);
    }

    final file = File(result.files.single.path!);
    final encryptedContent = await file.readAsString();

    // 復号
    String jsonString;
    try {
      jsonString = CryptoService.decryptText(
        encryptedContent,
        password,
      );
    } catch (e) {
      throw Exception(
        'パスワードが間違っているか、ファイルが破損しています。',
      );
    }

    // データ復元（追加モード）
    final List<dynamic> jsonList = jsonDecode(jsonString);
    int imported = 0;
    int skipped = 0;
    final storage = StorageService();

    for (final item in jsonList) {
      final map = Map<String, dynamic>.from(item as Map);
      // IDを除外して新規データとして追加（重複回避）
      map.remove('id');
      // 元のタイムスタンプがなければ現在時刻を設定
      map['created_at'] ??= DateTime.now().toIso8601String();
      map['updated_at'] ??= DateTime.now().toIso8601String();

      try {
        await storage.insertKey(KeyModel.fromMap(map));
        imported++;
      } catch (e) {
        // 無料版の制限に達した場合など
        skipped++;
      }
    }

    return (imported: imported, skipped: skipped);
  }

  // ─── Google Drive連携（有料版フック） ───

  /// Google Driveへエクスポートする（有料版）
  ///
  /// [password] 暗号化に使用するマスターパスワード
  ///
  /// Throws: [Exception] 無料版の場合
  Future<void> exportToGoogleDrive(String password) async {
    if (!AppConstants.isPro) {
      throw Exception(
        'Google Driveバックアップは有料版（Pro Plan）の機能です。',
      );
    }
    // TODO: Google Drive API連携実装
  }

  /// Google Driveからインポートする（有料版）
  ///
  /// [password] 復号に使用するマスターパスワード
  ///
  /// Throws: [Exception] 無料版の場合
  Future<void> importFromGoogleDrive(String password) async {
    if (!AppConstants.isPro) {
      throw Exception(
        'Google Driveバックアップは有料版（Pro Plan）の機能です。',
      );
    }
    // TODO: Google Drive API連携実装
  }
}
