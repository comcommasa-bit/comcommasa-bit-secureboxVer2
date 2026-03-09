/// 設定画面
///
/// 生体認証のON/OFF、データバックアップ/復元、
/// 全データリセット、ログアウト機能を提供する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/storage_service.dart';
import '../widgets/toast.dart';
import 'auth_screen.dart';

/// 設定画面ウィジェット
class SettingsScreen extends StatefulWidget {
  /// [SettingsScreen] を作成する
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _backupService = BackupService();
  final _storageService = StorageService();

  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 設定の初期値を読み込む
  Future<void> _loadSettings() async {
    final available = await _authService.isBiometricsAvailable;
    final enabled = await _authService.isBiometricsEnabled;

    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _biometricsEnabled = enabled;
      });
    }
  }

  /// 生体認証の有効/無効を切り替える
  Future<void> _toggleBiometrics(bool value) async {
    await _authService.setBiometricsEnabled(value);
    if (mounted) {
      setState(() => _biometricsEnabled = value);
      AppToast.showSuccess(
        context,
        value ? '生体認証を有効にしました' : '生体認証を無効にしました',
      );
    }
  }

  /// バックアップをエクスポートする
  Future<void> _exportBackup() async {
    final password = await _showPasswordDialog('バックアップ用パスワード');
    if (password == null) return;

    setState(() => _isLoading = true);
    try {
      final path = await _backupService.exportToLocalFile(password);
      if (mounted) {
        if (path != null) {
          AppToast.showSuccess(context, 'バックアップを保存しました');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// バックアップからインポートする
  Future<void> _importBackup() async {
    final password = await _showPasswordDialog('復元用パスワード');
    if (password == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _backupService.importFromLocalFile(password);
      if (mounted) {
        AppToast.showSuccess(
          context,
          '${result.imported}件インポート、${result.skipped}件スキップ',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 全データをリセットする
  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全データリセット'),
        content: const Text(
          'すべてのデータとマスターパスワードが削除されます。\n'
          'この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _storageService.deleteAllKeys();
      await _authService.clearAll();
      if (mounted) {
        AppToast.showSuccess(context, '全データをリセットしました');
        _navigateToAuth();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'リセットに失敗しました');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ログアウトして認証画面に戻る
  void _logout() {
    _navigateToAuth();
  }

  /// 認証画面に遷移する（スタックをクリア）
  void _navigateToAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  /// パスワード入力ダイアログを表示する
  Future<String?> _showPasswordDialog(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'マスターパスワード',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ─── セキュリティ ───
                const _SectionHeader(title: 'セキュリティ'),
                if (_biometricsAvailable)
                  SwitchListTile(
                    title: const Text('生体認証'),
                    subtitle: const Text('指紋・顔認証でロック解除'),
                    secondary: const Icon(Icons.fingerprint),
                    value: _biometricsEnabled,
                    onChanged: _toggleBiometrics,
                  ),
                if (!_biometricsAvailable)
                  const ListTile(
                    leading: Icon(Icons.fingerprint, color: Colors.grey),
                    title: Text('生体認証'),
                    subtitle: Text('このデバイスでは利用できません'),
                    enabled: false,
                  ),

                const Divider(),

                // ─── 外観 ───
                const _SectionHeader(title: '外観'),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('ダークモード'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeNotifier.value,
                    underline: const SizedBox.shrink(),
                    onChanged: (mode) async {
                      if (mode == null) return;
                      themeNotifier.value = mode;
                      const storage = FlutterSecureStorage();
                      await storage.write(
                        key: 'theme_mode',
                        value: mode == ThemeMode.dark
                            ? 'dark'
                            : mode == ThemeMode.light
                                ? 'light'
                                : 'system',
                      );
                      if (mounted) setState(() {});
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('自動'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('ライト'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('ダーク'),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // ─── データ管理 ───
                const _SectionHeader(title: 'データ管理'),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('バックアップ（エクスポート）'),
                  subtitle: const Text('.sbxファイルに保存'),
                  onTap: _exportBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('データ復元（インポート）'),
                  subtitle: const Text('.sbxファイルから復元'),
                  onTap: _importBackup,
                ),

                const Divider(),

                // ─── アカウント ───
                const _SectionHeader(title: 'アカウント'),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('ログアウト'),
                  onTap: _logout,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                  title: const Text(
                    '全データリセット',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('すべてのデータを削除'),
                  onTap: _resetAllData,
                ),
              ],
            ),
    );
  }
}

/// セクションヘッダー
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
