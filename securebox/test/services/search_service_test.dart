import 'package:flutter_test/flutter_test.dart';
import 'package:securebox/models/key_model.dart';
import 'package:securebox/services/search_service.dart';

void main() {
  group('SearchService', () {
    final testKeys = [
      KeyModel(
        id: 1,
        name: 'AWS本番',
        furigana: 'えーだぶりゅーえすほんばん',
        category: 'aws',
        type: 'api_key',
        value: 'AKIA...',
        memo: '本番環境用',
        createdAt: DateTime(2024, 1, 1),
      ),
      KeyModel(
        id: 2,
        name: 'Stripe Test Key',
        category: 'stripe',
        type: 'api_key',
        value: 'sk_test_...',
        memo: 'テスト用',
        createdAt: DateTime(2024, 1, 2),
      ),
      KeyModel(
        id: 3,
        name: 'GitHub Token',
        category: 'github',
        type: 'token',
        value: 'ghp_...',
        createdAt: DateTime(2024, 1, 3),
      ),
      KeyModel(
        id: 4,
        name: 'OpenAI APIキー',
        furigana: 'おーぷんえーあいえーぴーあいきー',
        category: 'openai',
        type: 'api_key',
        value: 'sk-...',
        memo: 'GPT-4用',
        createdAt: DateTime(2024, 1, 4),
      ),
    ];

    group('searchByKeyword', () {
      test('名前で検索できる', () {
        final results = SearchService.searchByKeyword(testKeys, 'AWS');
        expect(results.length, 1);
        expect(results.first.name, 'AWS本番');
      });

      test('ふりがなで検索できる', () {
        final results = SearchService.searchByKeyword(testKeys, 'えーだぶりゅー');
        expect(results.length, 1);
        expect(results.first.name, 'AWS本番');
      });

      test('メモで検索できる', () {
        final results = SearchService.searchByKeyword(testKeys, 'GPT-4');
        expect(results.length, 1);
        expect(results.first.name, 'OpenAI APIキー');
      });

      test('大文字小文字を区別しない', () {
        final results = SearchService.searchByKeyword(testKeys, 'github');
        expect(results.length, 1);
        expect(results.first.name, 'GitHub Token');
      });

      test('空文字列で全件返す', () {
        final results = SearchService.searchByKeyword(testKeys, '');
        expect(results.length, 4);
      });

      test('該当なしで空リスト', () {
        final results = SearchService.searchByKeyword(testKeys, '存在しない');
        expect(results, isEmpty);
      });
    });

    group('filterByCategory', () {
      test('カテゴリで絞り込める', () {
        final results = SearchService.filterByCategory(testKeys, 'aws');
        expect(results.length, 1);
        expect(results.first.category, 'aws');
      });

      test('"all"で全件返す', () {
        final results = SearchService.filterByCategory(testKeys, 'all');
        expect(results.length, 4);
      });

      test('空文字列で全件返す', () {
        final results = SearchService.filterByCategory(testKeys, '');
        expect(results.length, 4);
      });
    });

    group('search（複合検索）', () {
      test('キーワード+カテゴリの複合検索', () {
        final results = SearchService.search(
          testKeys,
          keyword: 'テスト',
          category: 'stripe',
        );
        expect(results.length, 1);
        expect(results.first.name, 'Stripe Test Key');
      });

      test('フィルタなしで全件', () {
        final results = SearchService.search(testKeys);
        expect(results.length, 4);
      });
    });
  });
}
