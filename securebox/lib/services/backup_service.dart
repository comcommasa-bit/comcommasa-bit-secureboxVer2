import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'crypto_service.dart';
import 'storage_service.dart';

/// Google Drive認証済みHTTPクライアント
class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// バックアップサービス
///
/// Google Driveへの暗号化バックアップとローカルファイルの
/// エクスポート/インポートを提供する
class BackupService {
  static const String _backupFileName = 'securebox_backup.enc';
  static const String _backupMimeType = 'application/octet-stream';
  static const String _folderMimeType = 'application/vnd.google-apps.folder';
  static const String _folderName = 'SecureBox Backup';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // --- ローカルバックアップ ---

  /// 全データを暗号化してJSON文字列にエクスポート
  ///
  /// 返り値: 暗号化されたバックアップデータ文字列
  static Future<String> exportToString(String masterPassword) async {
    final allData = await StorageService.exportAll();
    final jsonString = jsonEncode(allData);
    final encrypted = CryptoService.encryptText(jsonString, masterPassword);
    return encrypted;
  }

  /// 暗号化されたJSON文字列からデータをインポート
  static Future<void> importFromString(
    String encryptedData,
    String masterPassword,
  ) async {
    final jsonString = CryptoService.decryptText(encryptedData, masterPassword);
    final List<dynamic> decoded = jsonDecode(jsonString);
    final data = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    await StorageService.importAll(data);
  }

  // --- Google Drive バックアップ ---

  /// Googleにサインイン
  ///
  /// サインイン済みの場合はサイレント認証を試行
  static Future<GoogleSignInAccount?> signIn() async {
    var account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    return account;
  }

  /// Googleからサインアウト
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// 現在のサインイン状態を取得
  static Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Drive APIクライアントを取得
  static Future<drive.DriveApi?> _getDriveApi() async {
    final account = _googleSignIn.currentUser ?? await signIn();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final client = _AuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  /// バックアップ用フォルダのIDを取得（なければ作成）
  static Future<String?> _getOrCreateFolder(drive.DriveApi driveApi) async {
    // 既存フォルダを検索
    final query =
        "name = '$_folderName' and mimeType = '$_folderMimeType' and trashed = false";
    final fileList = await driveApi.files.list(q: query, spaces: 'drive');

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id;
    }

    // フォルダを作成
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = _folderMimeType;

    final created = await driveApi.files.create(folder);
    return created.id;
  }

  /// Google Driveにバックアップをアップロード
  static Future<bool> backupToDrive(String masterPassword) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final folderId = await _getOrCreateFolder(driveApi);
      if (folderId == null) return false;

      final encryptedData = await exportToString(masterPassword);
      final bytes = utf8.encode(encryptedData);

      // 既存バックアップを検索
      final query =
          "name = '$_backupFileName' and '$folderId' in parents and trashed = false";
      final existing = await driveApi.files.list(q: query, spaces: 'drive');

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
      );

      if (existing.files != null && existing.files!.isNotEmpty) {
        // 既存ファイルを更新
        await driveApi.files.update(
          drive.File(),
          existing.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        // 新規作成
        final file = drive.File()
          ..name = _backupFileName
          ..parents = [folderId]
          ..mimeType = _backupMimeType;

        await driveApi.files.create(file, uploadMedia: media);
      }

      return true;
    } catch (e) {
      debugPrint('Backup to Drive failed: $e');
      return false;
    }
  }

  /// Google Driveからバックアップを復元
  static Future<bool> restoreFromDrive(String masterPassword) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final folderId = await _getOrCreateFolder(driveApi);
      if (folderId == null) return false;

      // バックアップファイルを検索
      final query =
          "name = '$_backupFileName' and '$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('バックアップファイルが見つかりません');
      }

      final fileId = fileList.files!.first.id!;

      // ファイルをダウンロード
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dataBytes = <int>[];
      await for (final chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      final encryptedData = utf8.decode(dataBytes);
      await importFromString(encryptedData, masterPassword);

      return true;
    } catch (e) {
      debugPrint('Restore from Drive failed: $e');
      return false;
    }
  }
}
