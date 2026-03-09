/// 一覧画面
///
/// キーの一覧表示、検索、カテゴリフィルタ機能を提供する。
library;

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';
import '../widgets/key_list_item.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';
import 'settings_screen.dart';

/// キー一覧画面ウィジェット
class ListScreen extends StatefulWidget {
  /// [ListScreen] を作成する
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _storage = StorageService();
  final _searchController = TextEditingController();

  List<KeyModel> _allKeys = [];
  List<KeyModel> _filteredKeys = [];
  String? _selectedCategory;
  String _sortBy = 'updated_at'; // 'updated_at', 'name', 'category'
  bool _sortAscending = false; // false = 新しい順
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// データベースからキーを読み込む
  Future<void> _loadKeys() async {
    setState(() => _isLoading = true);
    final keys = await _storage.getAllKeys();
    if (mounted) {
      setState(() {
        _allKeys = keys;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  /// 検索キーワードが変更されたときに呼ばれる
  void _onSearchChanged() {
    _applyFilters();
  }

  /// カテゴリが選択されたときに呼ばれる
  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  /// 検索とカテゴリフィルタを適用する
  void _applyFilters() {
    List<KeyModel> keys = List.from(_allKeys);

    // カテゴリフィルタ
    if (_selectedCategory != null) {
      keys = SearchService.filterByCategory(keys, _selectedCategory!);
    }

    // 検索フィルタ
    keys = SearchService.filterKeys(keys, _searchController.text);

    // ソート
    keys.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
        case 'category':
          result = a.category.compareTo(b.category);
        default:
          result = a.updatedAt.compareTo(b.updatedAt);
      }
      return _sortAscending ? result : -result;
    });

    setState(() => _filteredKeys = keys);
  }

  /// 新規追加画面へ遷移する
  Future<void> _navigateToAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditScreen(
          // ★修正点: 選択中のカテゴリを渡す
          initialCategory: _selectedCategory,
        ),
      ),
    );
    if (result == true) _loadKeys();
  }

  /// 詳細画面へ遷移する
  Future<void> _navigateToDetail(KeyModel keyModel) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(keyModel: keyModel),
      ),
    );
    if (result == true) _loadKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // ソート
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = value == 'name';
                }
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'updated_at',
                child: Row(
                  children: [
                    const Text('更新日'),
                    if (_sortBy == 'updated_at')
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    const Text('名前'),
                    if (_sortBy == 'name')
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    const Text('カテゴリ'),
                    if (_sortBy == 'category')
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ],
          ),
          // カテゴリフィルタ
          PopupMenuButton<String?>(
            icon: Icon(
              _selectedCategory == null
                  ? Icons.filter_list
                  : Icons.filter_list_alt,
            ),
            onSelected: _onCategorySelected,
            itemBuilder: (context) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('全カテゴリ'),
              ),
              ...AppConstants.categories.map(
                (cat) => PopupMenuItem<String?>(
                  value: cat,
                  child: Text(cat),
                ),
              ),
            ],
          ),
          // 設定画面
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredKeys.isEmpty
              ? const Center(child: Text('データがありません'))
              : RefreshIndicator(
                  onRefresh: _loadKeys,
                  child: ListView.builder(
                    itemCount: _filteredKeys.length,
                    itemBuilder: (context, index) {
                      final key = _filteredKeys[index];
                      return KeyListItem(
                        keyModel: key,
                        onTap: () => _navigateToDetail(key),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
