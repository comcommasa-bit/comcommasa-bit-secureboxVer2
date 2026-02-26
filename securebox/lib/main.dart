import 'package:flutter/material.dart';

import 'screens/list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecureBoxApp());
}

/// SecureBox アプリケーション
///
/// パスワード・APIキーを安全に保管するアプリ
class SecureBoxApp extends StatelessWidget {
  const SecureBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: const ListScreen(),
    );
  }
}
