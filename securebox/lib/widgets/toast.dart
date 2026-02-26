import 'package:flutter/material.dart';

/// トースト通知ウィジェット
///
/// 成功・エラーメッセージをSnackBarで表示する
class Toast {
  Toast._();

  /// 成功メッセージを表示
  static void show(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 成功メッセージを表示（ショートカット）
  static void success(BuildContext context, String message) {
    show(context, message, isError: false);
  }

  /// エラーメッセージを表示（ショートカット）
  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }
}
