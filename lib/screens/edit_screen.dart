/// 編集画面
///
/// キーの新規追加・編集を行う。
/// フォーム: タイトル、カテゴリ、キー種類、キー値、メモ
library;

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../widgets/toast.dart';

/// キー編集画面（新規追加 / 編集兼用）
class EditScreen extends StatefulWidget {
  /// 編集対象のキー（nullなら新規追加）
  final KeyModel? keyModel;

  /// [EditScreen] を作成する
  const EditScreen({super.key, this.keyModel});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storage = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _valueController;
  late final TextEditingController _memoController;
  late String _selectedCategory;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.keyModel != null;
    _nameController = TextEditingController(
      text: widget.keyModel?.name ?? '',
    );
    _typeController = TextEditingController(
      text: widget.keyModel?.type ?? '',
    );
    _valueController = TextEditingController(
      text: widget.keyModel?.value ?? '',
    );
    _memoController = TextEditingController(
      text: widget.keyModel?.memo ?? '',
    );
    _selectedCategory =
        widget.keyModel?.category ?? AppConstants.categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _valueController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// 保存処理
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final key = KeyModel(
        id: widget.keyModel?.id,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        type: _typeController.text.trim(),
        value: _valueController.text.trim(),
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        createdAt: widget.keyModel?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await _storage.updateKey(key);
      } else {
        await _storage.insertKey(key);
      }

      if (mounted) {
        AppToast.showSuccess(
          context,
          _isEditing ? '更新しました' : '追加しました',
        );
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      if (mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 削除処理
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このキーを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _storage.deleteKey(widget.keyModel!.id!);
    if (mounted) {
      AppToast.showSuccess(context, '削除しました');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'キーを編集' : 'キーを追加'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // キー名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'キー名 *',
                  hintText: '例: AWS本番キー',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => Validators.notEmpty(
                  v,
                  message: 'キー名を入力してください',
                ),
              ),
              const SizedBox(height: 16),

              // カテゴリ
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ *',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedCategory = v);
                  }
                },
              ),
              const SizedBox(height: 16),

              // キー種類
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'キー種類 *',
                  hintText: '例: API Key, Password, Secret',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => Validators.notEmpty(
                  v,
                  message: 'キー種類を入力してください',
                ),
              ),
              const SizedBox(height: 16),

              // キー値
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'キー値 *',
                  hintText: '例: sk_test_abc123...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => Validators.notEmpty(
                  v,
                  message: 'キー値を入力してください',
                ),
              ),
              const SizedBox(height: 16),

              // メモ
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'メモ（任意）',
                  hintText: '用途や注意事項など',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // 保存ボタン
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEditing ? '更新する' : '追加する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
