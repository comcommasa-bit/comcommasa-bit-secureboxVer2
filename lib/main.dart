/// パスワード保管庫 アプリエントリーポイント
///
/// アプリの初期化とルーティング設定を行う。
library;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/constants.dart';
import 'screens/auth_screen.dart';

/// テーマモードの通知用
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 保存されたテーマ設定を読み込み
  const storage = FlutterSecureStorage();
  final savedTheme = await storage.read(key: 'theme_mode');
  if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    themeNotifier.value = ThemeMode.light;
  }

  runApp(const SecureBoxApp());
}

/// パスワード保管庫 アプリケーション
class SecureBoxApp extends StatelessWidget {
  /// [SecureBoxApp] を作成する
  const SecureBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const AuthScreen(),
        );
      },
    );
  }
}
