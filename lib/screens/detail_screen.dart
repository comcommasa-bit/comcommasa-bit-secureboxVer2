/// 詳細画面
///
/// キーの全情報を表示する。
/// 編集ボタンで編集画面へ遷移する。
library;

import 'package:flutter/material.dart';

import '../models/key_model.dart';
import '../widgets/key_detail_card.dart';
import 'edit_screen.dart';

/// キー詳細画面
class DetailScreen extends StatelessWidget {
  /// 表示するキーデータ
  final KeyModel keyModel;

  /// [DetailScreen] を作成する
  const DetailScreen({super.key, required this.keyModel});

  /// 編集画面へ遷移する
  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditScreen(keyModel: keyModel),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(keyModel.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: KeyDetailCard(keyModel: keyModel),
      ),
    );
  }
}
