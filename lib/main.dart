/// SecureBox アプリエントリーポイント
///
/// アプリの初期化とルーティング設定を行う。
library;

import 'package:flutter/material.dart';

import 'config/constants.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const SecureBoxApp());
}

/// SecureBox アプリケーション
class SecureBoxApp extends StatelessWidget {
  /// [SecureBoxApp] を作成する
  const SecureBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
