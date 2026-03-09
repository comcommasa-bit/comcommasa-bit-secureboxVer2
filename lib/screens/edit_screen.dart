/// 編集画面
///
/// キーの新規作成と既存データの編集を行う。
library;

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../widgets/toast.dart';

/// キー編集画面ウィジェット
class EditScreen extends StatefulWidget {
  /// 編集対象のキーデータ（新規作成時は null）
  final KeyModel? keyModel;

  /// ★修正点: 新規作成時の初期カテゴリ
  final String? initialCategory;

  /// [EditScreen] を作成する
  const EditScreen({super.key, this.keyModel, this.initialCategory});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _memoController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  String? _selectedCategory;
  String? _selectedType;
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _isNew = widget.keyModel == null;

    _nameController = TextEditingController(text: widget.keyModel?.name);
    _usernameController =
        TextEditingController(text: widget.keyModel?.username);
    _emailController = TextEditingController(text: widget.keyModel?.email);
    _valueController = TextEditingController(text: widget.keyModel?.value);
    _memoController = TextEditingController(text: widget.keyModel?.memo);

    if (_isNew) {
      // ★修正点: 初期カテゴリを設定
      _selectedCategory =
          widget.initialCategory ?? AppConstants.categories.first;
      _selectedType = AppConstants.keyTypes.first;
    } else {
      _selectedCategory = widget.keyModel!.category;
      // 既存データのtypeがリストにない場合は「その他」にフォールバック
      _selectedType = AppConstants.keyTypes.contains(widget.keyModel!.type)
          ? widget.keyModel!.type
          : AppConstants.keyTypes.last;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _valueController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// データを保存する
  Future<void> _saveKey() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final username = _usernameController.text.trim().isEmpty
        ? null
        : _usernameController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();

    final key = _isNew
        ? KeyModel(
            name: _nameController.text,
            category: _selectedCategory!,
            type: _selectedType!,
            value: _valueController.text,
            memo: _memoController.text,
            username: username,
            email: email,
            createdAt: now,
            updatedAt: now,
          )
        : widget.keyModel!.copyWith(
            name: _nameController.text,
            category: _selectedCategory!,
            type: _selectedType!,
            value: _valueController.text,
            memo: _memoController.text,
            username: username,
            email: email,
            updatedAt: now,
          );

    try {
      if (_isNew) {
        await _storage.insertKey(key);
      } else {
        await _storage.updateKey(key);
      }
      if (mounted) {
        AppToast.showSuccess(context, '保存しました');
        Navigator.pop(context, true); // true を返して一覧を更新
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, e.toString());
      }
    }
  }

  /// データを削除する
  Future<void> _deleteKey() async {
    if (_isNew) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このデータを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
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
        title: Text(_isNew ? '新規作成' : '編集'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteKey,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveKey,
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名前'),
                validator: Validators.notEmpty,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'カテゴリ'),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (v) =>
                    Validators.notEmpty(v, message: 'カテゴリを選択してください'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: '種類'),
                items: AppConstants.keyTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (v) =>
                    Validators.notEmpty(v, message: '種類を選択してください'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'ユーザー名（任意）',
                  hintText: '例: user@example.com',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス（任意）',
                  hintText: '例: mail@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'キー / パスワード *',
                ),
                validator: Validators.notEmpty,
                obscureText: true,
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: 'メモ'),
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
