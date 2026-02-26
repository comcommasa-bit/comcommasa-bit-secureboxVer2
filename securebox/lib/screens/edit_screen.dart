import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../widgets/toast.dart';

/// キー編集画面
///
/// 新規追加・既存編集の両方に対応するフォーム画面
class EditScreen extends StatefulWidget {
  /// 編集対象のキーデータ（nullなら新規追加）
  final KeyModel? keyData;

  const EditScreen({
    super.key,
    this.keyData,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _furiganaController;
  late final TextEditingController _valueController;
  late final TextEditingController _memoController;
  late String _selectedCategory;
  late String _selectedType;
  bool _isSaving = false;

  /// 新規追加モードかどうか
  bool get _isNew => widget.keyData == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.keyData?.name ?? '');
    _furiganaController =
        TextEditingController(text: widget.keyData?.furigana ?? '');
    _valueController = TextEditingController(text: widget.keyData?.value ?? '');
    _memoController = TextEditingController(text: widget.keyData?.memo ?? '');
    _selectedCategory = widget.keyData?.category ?? Constants.categories.first;
    _selectedType = widget.keyData?.type ?? Constants.keyTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _furiganaController.dispose();
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
        id: widget.keyData?.id,
        name: _nameController.text.trim(),
        furigana: _furiganaController.text.trim().isEmpty
            ? null
            : _furiganaController.text.trim(),
        category: _selectedCategory,
        type: _selectedType,
        value: _valueController.text,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        createdAt: widget.keyData?.createdAt ?? now,
        updatedAt: _isNew ? null : now,
      );

      if (_isNew) {
        await StorageService.insertKey(key);
      } else {
        await StorageService.updateKey(key);
      }

      if (mounted) {
        Toast.success(context, _isNew ? '追加しました' : '更新しました');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'キー追加' : 'キー編集'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // キー名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'キー名 *',
                  hintText: '例: AWS本番アカウント',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateKeyName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // ふりがな
              TextFormField(
                controller: _furiganaController,
                decoration: const InputDecoration(
                  labelText: 'ふりがな',
                  hintText: '例: えーだぶりゅーえすほんばんあかうんと',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // カテゴリ
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ *',
                  border: OutlineInputBorder(),
                ),
                items: Constants.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(Constants.categoryNames[cat] ?? cat),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // キーの種類
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'キーの種類 *',
                  border: OutlineInputBorder(),
                ),
                items: Constants.keyTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(Constants.keyTypeNames[type] ?? type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // キー値
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'キー値 *',
                  hintText: 'パスワードやAPIキーを入力',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateKeyValue,
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // メモ
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                  hintText: '用途や注意事項など',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
