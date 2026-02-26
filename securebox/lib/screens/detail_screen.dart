import 'package:flutter/material.dart';

import '../models/key_model.dart';
import '../services/storage_service.dart';
import '../widgets/key_detail_card.dart';
import '../widgets/toast.dart';
import 'edit_screen.dart';

/// キー詳細画面
///
/// キーの全情報を表示し、編集・削除操作を提供する
class DetailScreen extends StatefulWidget {
  /// 表示するキーデータ
  final KeyModel keyData;

  const DetailScreen({
    super.key,
    required this.keyData,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late KeyModel _keyData;

  @override
  void initState() {
    super.initState();
    _keyData = widget.keyData;
  }

  /// 編集画面へ遷移
  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(keyData: _keyData),
      ),
    );

    if (result == true && _keyData.id != null) {
      // 編集後にデータを再取得
      final updated = await StorageService.getKeyById(_keyData.id!);
      if (updated != null && mounted) {
        setState(() => _keyData = updated);
      }
    }
  }

  /// キーを削除
  Future<void> _deleteKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${_keyData.name}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && _keyData.id != null) {
      await StorageService.deleteKey(_keyData.id!);
      if (mounted) {
        Toast.success(context, '削除しました');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('キー詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
            tooltip: '編集',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteKey,
            tooltip: '削除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: KeyDetailCard(keyData: _keyData),
      ),
    );
  }
}
