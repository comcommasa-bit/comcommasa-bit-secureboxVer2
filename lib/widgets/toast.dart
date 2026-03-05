/// トースト通知ウィジェット
///
/// 成功・エラーメッセージをスナックバーで表示する。
library;

import 'package:flutter/material.dart';

/// トースト通知を表示するユーティリティ
class AppToast {
  AppToast._();

  /// 成功メッセージを表示する
  ///
  /// [context] BuildContext
  /// [message] 表示するメッセージ
  static void showSuccess(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// エラーメッセージを表示する
  ///
  /// [context] BuildContext
  /// [message] 表示するメッセージ
  static void showError(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
