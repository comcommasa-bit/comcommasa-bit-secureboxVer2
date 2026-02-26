import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';
import '../widgets/key_list_item.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';

/// キー一覧画面
///
/// 全キーをリスト表示し、検索・カテゴリフィルタを提供する
class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<KeyModel> _allKeys = [];
  List<KeyModel> _filteredKeys = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  final _searchController = TextEditingController();

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

  /// キーを読み込む
  Future<void> _loadKeys() async {
    setState(() => _isLoading = true);
    try {
      final keys = await StorageService.getAllKeys();
      setState(() {
        _allKeys = keys;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 検索・フィルタを適用
  void _applyFilters() {
    _filteredKeys = SearchService.search(
      _allKeys,
      keyword: _searchQuery,
      category: _selectedCategory,
    );
  }

  /// 検索クエリ変更時
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  /// カテゴリ変更時
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  /// 詳細画面へ遷移
  Future<void> _navigateToDetail(KeyModel key) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(keyData: key),
      ),
    );
    // 戻ったときにリロード（編集・削除された可能性がある）
    _loadKeys();
  }

  /// 新規追加画面へ遷移
  Future<void> _navigateToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditScreen(),
      ),
    );
    _loadKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureBox'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // カテゴリフィルタ
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildCategoryChip('all', 'すべて'),
                ...Constants.categories.map((cat) {
                  return _buildCategoryChip(
                    cat,
                    Constants.categoryNames[cat] ?? cat,
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // キー数表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredKeys.length}件',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_allKeys.length} / ${Constants.maxFreeKeys}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _allKeys.length >= Constants.maxFreeKeys
                            ? Colors.red
                            : Colors.grey,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // キーリスト
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredKeys.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.key_off,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _allKeys.isEmpty
                                  ? 'キーがまだありません\n右下の＋ボタンから追加してください'
                                  : '検索結果がありません',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadKeys,
                        child: ListView.builder(
                          itemCount: _filteredKeys.length,
                          itemBuilder: (context, index) {
                            final key = _filteredKeys[index];
                            return KeyListItem(
                              keyData: key,
                              onTap: () => _navigateToDetail(key),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// カテゴリフィルタチップを構築
  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onCategoryChanged(value),
      ),
    );
  }
}
