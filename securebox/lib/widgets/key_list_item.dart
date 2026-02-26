import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/key_model.dart';

/// キー一覧のリストアイテムウィジェット
class KeyListItem extends StatelessWidget {
  /// 表示するキーデータ
  final KeyModel keyData;

  /// タップ時のコールバック
  final VoidCallback onTap;

  const KeyListItem({
    super.key,
    required this.keyData,
    required this.onTap,
  });

  /// カテゴリに応じたアイコンを返す
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'stripe':
        return Icons.payment;
      case 'aws':
        return Icons.cloud;
      case 'openai':
        return Icons.psychology;
      case 'google':
        return Icons.g_mobiledata;
      case 'github':
        return Icons.code;
      default:
        return Icons.key;
    }
  }

  /// カテゴリに応じた色を返す
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'stripe':
        return Colors.purple;
      case 'aws':
        return Colors.orange;
      case 'openai':
        return Colors.teal;
      case 'google':
        return Colors.blue;
      case 'github':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName =
        Constants.categoryNames[keyData.category] ?? keyData.category;
    final typeName =
        Constants.keyTypeNames[keyData.type] ?? keyData.type;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(keyData.category),
          child: Icon(
            _getCategoryIcon(keyData.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          keyData.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$categoryName / $typeName'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
