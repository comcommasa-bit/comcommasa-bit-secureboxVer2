/// 一覧画面
///
/// キーのリスト表示、カテゴリフィルター、検索バーを提供する。
/// FABから新規追加画面へ遷移する。
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

/// キー一覧画面
class ListScreen extends StatefulWidget {
  /// [ListScreen] を作成する
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _searchController =
      TextEditingController();

  List<KeyModel> _allKeys = [];
  List<KeyModel> _filteredKeys = [];
  String _selectedCategory = 'すべて';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// キーをDBから読み込む
  Future<void> _loadKeys() async {
    setState(() => _isLoading = true);
    try {
      _allKeys = await _storage.getAllKeys();
      _applyFilters();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 検索とカテゴリフィルターを適用する
  void _applyFilters() {
    var result = _allKeys;

    // カテゴリフィルター
    if (_selectedCategory != 'すべて') {
      result = SearchService.filterByCategory(
        result,
        _selectedCategory,
      );
    }

    // キーワード検索
    result = SearchService.filterKeys(
      result,
      _searchController.text,
    );

    setState(() => _filteredKeys = result);
  }

  /// 新規追加画面へ遷移する
  Future<void> _navigateToAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditScreen()),
    );
    if (result == true) _loadKeys();
  }

  /// 詳細画面へ遷移する
  Future<void> _navigateToDetail(KeyModel key) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(keyModel: key),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
              _loadKeys();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(
              AppConstants.defaultPadding,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'キーワードで検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                ),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // カテゴリフィルタータブ
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              children: [
                _buildCategoryChip('すべて'),
                ...AppConstants.categories.map(
                  _buildCategoryChip,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // キーリスト
          Expanded(child: _buildKeyList()),
        ],
      ),

      // 追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// カテゴリチップを構築する
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          _applyFilters();
        },
      ),
    );
  }

  /// キーリストを構築する
  Widget _buildKeyList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vpn_key_off,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _allKeys.isEmpty
                  ? 'キーがまだありません\n+ボタンで追加しましょう'
                  : '一致するキーが見つかりません',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
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
    );
  }
}
