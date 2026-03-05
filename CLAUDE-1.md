# SecureBox - パスワード保管庫

## プロジェクト概要

パスワードやAPIキーを安全に保管するAndroidネイティブアプリ。
データはデバイスのローカルストレージに暗号化保存。
Google Driveに暗号化ファイルとしてエクスポート/インポート可能。
将来的にiOS対応予定。

---

## 技術スタック

### 言語・フレームワーク
- **Flutter 3.x** (Dart)
- React Nativeではなく、Flutter採用（理由: パフォーマンス、UI品質、Google製）

### ターゲット
- **現在**: Android のみ
- **将来**: iOS, Web対応

### 主要パッケージ
- `sqflite` - ローカルデータベース
- `encrypt` - AES-256暗号化
- `local_auth` - 指紋/顔認証
- `google_sign_in` + `googleapis` - Google Drive連携
- `flutter_secure_storage` - 暗号化キー保存

---

## アーキテクチャ

### データフロー

```
ユーザー入力
  ↓
マスターパスワードで暗号化
  ↓
SQLite（ローカル保存）
  ↓
バックアップ時: Google Driveにエクスポート
  ↓
復元時: Google Driveからインポート → 復号 → SQLite
```

### 暗号化方式
- **AES-256-GCM**
- **PBKDF2** 鍵導出（60万回イテレーション）
- マスターパスワードから暗号化キーを生成

---

## プラン

### 無料版（Free Plan）
- 保存数: 10個まで
- 基本機能のみ

### 有料版（Pro Plan）
- 保存数: 無制限
- AI機能（Gemini API）
- 自動バックアップ
- Stripe決済（月額980円）

---

## 機能一覧

### 無料版

#### データ管理
- キーの追加（10個まで）
- キーの編集
- キーの削除
- キーの一覧表示
- カテゴリ別表示（6種類: Stripe, AWS, OpenAI, Google, GitHub, その他）
- 検索機能

#### セキュリティ
- マスターパスワード設定
- AES-256暗号化
- PBKDF2鍵導出（60万回）
- キー値の表示/非表示切り替え
- コピー機能
- 指紋認証（WebAuthn API相当）
- 顔認証（WebAuthn API相当）

#### ストレージ
- SQLite（ローカル保存）
- 暗号化データ保存

#### バックアップ
- Google Driveへエクスポート
- Google Driveからインポート
- ローカルファイルダウンロード
- ローカルファイルアップロード

#### UI
- リスト表示
- 詳細画面
- 編集画面（分離型: 詳細→編集ボタン→編集画面→保存）
- レスポンシブデザイン
- **アプリアイコン**: 猫が鍵を抱えているデザイン（`assets/icon/app-icon.png`）
  - `flutter_launcher_icons` パッケージで Android/iOS 両対応で生成すること
  - 詳細は `assets/icon/README.md` を参照

#### 将来の拡張性（有料版対応の準備）
- プラン判定機能
- 保存数制限のロジック
- 機能フラグシステム
- 課金状態の管理フィールド

### 有料版（追加機能）

#### データ管理
- 無制限保存
- タグ機能
- 有効期限設定
- 使用履歴の詳細記録

#### AI機能
- Gemini API連携
- パスワード強度分析
- 類似キー検出
- セキュリティリスク警告

#### バックアップ
- 自動バックアップスケジュール
- バックアップ履歴管理
- 複数バックアップ保持

#### 課金
- Stripe決済（月額980円）
- サブスクリプション管理
- 決済履歴表示

---

## ファイル構成

```
securebox/
├── CLAUDE.md                           # このファイル（AI向け設計書）
├── README.md                           # プロジェクト説明
├── pubspec.yaml                        # Flutter依存関係
├── android/                            # Android固有設定
├── ios/                                # iOS固有設定（将来用）
├── lib/
│   ├── main.dart                       # アプリエントリーポイント
│   ├── config/
│   │   └── constants.dart              # 定数・設定
│   ├── models/
│   │   └── key_model.dart              # キーデータモデル
│   ├── screens/
│   │   ├── list_screen.dart            # 一覧画面
│   │   ├── detail_screen.dart          # 詳細画面
│   │   └── edit_screen.dart            # 編集画面
│   ├── widgets/
│   │   ├── key_list_item.dart          # リストアイテム
│   │   ├── key_detail_card.dart        # 詳細カード
│   │   └── toast.dart                  # 通知
│   ├── services/
│   │   ├── crypto_service.dart         # 暗号化・復号化
│   │   ├── storage_service.dart        # SQLite操作
│   │   ├── backup_service.dart         # バックアップ機能
│   │   ├── auth_service.dart           # 生体認証
│   │   └── search_service.dart         # 検索機能
│   └── utils/
│       ├── validators.dart             # バリデーション
│       └── helpers.dart                # ヘルパー関数
└── test/
    ├── models/
    │   └── key_model_test.dart
    ├── services/
    │   ├── crypto_service_test.dart
    │   ├── storage_service_test.dart
    │   └── backup_service_test.dart
    └── widgets/
        └── key_list_item_test.dart
```

---

## 各ファイルの役割と機能

### lib/main.dart
- **役割**: アプリのエントリーポイント
- **機能**: アプリ初期化、ルーティング設定
- **依存**: 全画面、全サービス
- **完成条件**: アプリ起動成功

### lib/config/constants.dart
- **役割**: 定数・設定管理
- **機能**: 
  - カテゴリ定義（Stripe, AWS, OpenAI, Google, GitHub, その他）
  - 保存数制限（無料版: 10個）
  - 暗号化設定（イテレーション回数: 60万回）
  - Google Drive API設定
- **依存**: なし
- **完成条件**: 全定数定義完了

### lib/models/key_model.dart
- **役割**: キーデータモデル
- **機能**:
  - データ構造定義（id, name, category, type, value, memo, created_at）
  - JSON変換（fromJson, toJson）
- **依存**: なし
- **完成条件**: モデル定義完了

### lib/services/crypto_service.dart
- **役割**: 暗号化・復号化
- **機能**:
  - AES-256-GCM暗号化
  - PBKDF2鍵導出（60万回）
  - マスターパスワード検証
- **使用パッケージ**: `encrypt`, `crypto`
- **依存**: なし
- **完成条件**: 暗号化・復号化テスト成功

### lib/services/storage_service.dart
- **役割**: データの保存・読み込み
- **機能**:
  - SQLite操作（CRUD）
  - キーの追加・編集・削除・取得
  - カテゴリ別取得
  - 保存数制限チェック
- **使用パッケージ**: `sqflite`
- **依存**: crypto_service.dart（暗号化済みデータを保存）
- **完成条件**: データ保存・読み込みテスト成功

### lib/services/auth_service.dart
- **役割**: 生体認証
- **機能**:
  - 指紋認証
  - 顔認証
  - 認証状態管理
- **使用パッケージ**: `local_auth`
- **依存**: なし
- **完成条件**: 認証テスト成功

### lib/services/backup_service.dart
- **役割**: バックアップ機能
- **機能**:
  - Google Driveへエクスポート
  - Google Driveからインポート
  - ローカルファイルダウンロード
  - ローカルファイルアップロード
- **使用パッケージ**: `google_sign_in`, `googleapis`
- **依存**: storage_service.dart, crypto_service.dart
- **完成条件**: バックアップ・復元テスト成功

### lib/services/search_service.dart
- **役割**: 検索機能
- **機能**:
  - キーワード検索
  - カテゴリフィルタリング
  - タグフィルタリング（有料版）
- **依存**: なし
- **完成条件**: 検索テスト成功

### lib/screens/list_screen.dart
- **役割**: 一覧画面
- **機能**:
  - キーリスト表示
  - カテゴリ別表示
  - 検索バー
  - FAB（追加ボタン）
- **依存**: storage_service.dart, search_service.dart, widgets/key_list_item.dart
- **完成条件**: リスト表示成功

### lib/screens/detail_screen.dart
- **役割**: 詳細画面
- **機能**:
  - キー情報表示
  - キー値のコピー機能
  - タップでコピー / 長押しで3秒表示
  - 編集ボタン
- **依存**: storage_service.dart, widgets/key_detail_card.dart
- **完成条件**: 詳細表示・コピー成功

### lib/screens/edit_screen.dart
- **役割**: 編集画面
- **機能**:
  - フォーム表示（タイトル、カテゴリ、キー種類、キー値、メモ）
  - 保存機能
  - 削除機能
  - 新規追加/編集の切り替え
- **依存**: storage_service.dart
- **完成条件**: 編集・保存・削除成功

### lib/widgets/key_list_item.dart
- **役割**: リストアイテムウィジェット
- **機能**:
  - タイトル表示
  - ふりがな表示
  - タップで詳細画面へ
- **依存**: models/key_model.dart
- **完成条件**: 表示成功

### lib/widgets/key_detail_card.dart
- **役割**: 詳細カードウィジェット
- **機能**:
  - キー情報表示
  - コピー機能UI
- **依存**: models/key_model.dart
- **完成条件**: 表示成功

### lib/widgets/toast.dart
- **役割**: 通知ウィジェット
- **機能**:
  - トースト通知表示
  - 成功・エラーメッセージ
- **依存**: なし
- **完成条件**: 通知表示成功

### lib/utils/validators.dart
- **役割**: バリデーション
- **機能**:
  - 入力チェック
  - パスワード強度チェック（有料版）
- **依存**: なし
- **完成条件**: バリデーション成功

### lib/utils/helpers.dart
- **役割**: ヘルパー関数
- **機能**:
  - 日付フォーマット
  - 文字列操作
- **依存**: なし
- **完成条件**: 各関数動作確認

---

## 開発順序

### フェーズ1: 基盤（独立して完成可能）
1. **constants.dart** - 設定定義
2. **key_model.dart** - データモデル
3. **crypto_service.dart** - 暗号化機能
4. **toast.dart** - 通知機能
5. **validators.dart** - バリデーション
6. **helpers.dart** - ヘルパー関数

### フェーズ2: コア機能（基盤依存）
7. **storage_service.dart** - データ保存（crypto依存）
8. **search_service.dart** - 検索機能

### フェーズ3: UI（コア機能依存）
9. **key_list_item.dart** - リストアイテムウィジェット
10. **key_detail_card.dart** - 詳細カードウィジェット
11. **list_screen.dart** - 一覧画面（storage, search依存）
12. **detail_screen.dart** - 詳細画面（storage依存）
13. **edit_screen.dart** - 編集画面（storage依存）

### フェーズ4: 高度な機能
14. **auth_service.dart** - 生体認証
15. **backup_service.dart** - バックアップ（storage, crypto依存）

### フェーズ5: 統合
16. **main.dart** - 全体統合・ルーティング
17. 最終調整・テスト

---

## コーディング規約

### Dart標準に準拠
- **変数名**: camelCase
- **クラス名**: PascalCase
- **定数**: lowerCamelCase または UPPER_SNAKE_CASE
- **ファイル名**: snake_case

### ドキュメント
- 全関数に `///` ドキュメントコメントを記載
- クラスにもドキュメントを記載

```dart
/// ユーザーのキーを暗号化して保存する
/// 
/// [key] 保存するキーデータ
/// [password] マスターパスワード
/// 
/// Returns: 保存成功時は true
Future<bool> saveKey(KeyModel key, String password) async {
  // 実装
}
```

### テスト
- テストは `flutter_test` で記述
- 各サービスには対応するテストファイルを作成
- テスト駆動開発（TDD）を推奨

### フォーマット
- `dart format` で自動フォーマット
- 行の長さ: 80文字推奨

---

## テスト戦略

### テスト駆動開発（TDD）
機能実装前にテストを書く。

**例**:
```
「storage_service のテストを先に書いて。
 正常系: キーを保存して取得できる
 異常系: 存在しないキーを取得したらnull
 異常系: 10個超えて保存しようとしたらエラー」

→ テストが通るように実装
```

### テストの種類
1. **Unit Test**: 各サービス・関数の単体テスト
2. **Widget Test**: UI要素のテスト
3. **Integration Test**: 画面遷移・全体フローのテスト

---

## 重要なTips

### 1. エラー時はスタックトレースを貼る
エラーが出たら、エラーメッセージをそのまま貼り付ける。
Claude が正確に原因を特定して修正方法を提案できる。

```
エラーが出ました：
[エラーメッセージをそのままコピペ]

どう修正すればいい？
```

### 2. .gitignore を活用
Claude は `.gitignore` に記載されたファイルを読み込まない。
不要なファイルを除外してコンテキストを節約。

```gitignore
# 読ませない
*.log
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# 読ませる（.gitignoreに入れない）
lib/config/constants.dart
pubspec.yaml
CLAUDE.md
```

### 3. 重要ファイル優先
Claude に重要なファイルを明示して、そこに集中させる。

```
## 今回修正するファイル
- lib/services/storage_service.dart
- lib/models/key_model.dart
- test/services/storage_service_test.dart

この3ファイルだけ見て修正して。
```

### 4. 段階的に実装
一度に全部実装しない。機能ごとに分けて実装・テスト。

**良い例**:
```
1. まず storage_service.dart の保存機能だけ実装
2. テストして動作確認
3. 次に取得機能を実装
4. テストして動作確認
```

**悪い例**:
```
storage_service.dart を全部一気に実装
→ エラーが多発
→ どこが悪いか分からない
```

---

## ワークフロー（新機能追加時）

### 標準的な流れ
1. **要件確認**: 何を実装するか明確にする
2. **テスト作成**: 先にテストを書く（TDD）
3. **実装**: テストが通るようにコードを書く
4. **動作確認**: 実機で動作確認
5. **コミット**: Git にコミット

### 例: 新しいカテゴリ追加
1. `constants.dart` にカテゴリ追加
2. `key_model.dart` のバリデーション確認
3. UI（list_screen.dart）にカテゴリ表示追加
4. テスト実行
5. コミット

---

## Git Hooks（後で設定）

コミット前に自動でテスト・フォーマット・静的解析を実行。

```bash
# .git/hooks/pre-commit
flutter test          # テスト実行
dart format --set-exit-if-changed lib/  # フォーマットチェック
dart analyze          # 静的解析
```

品質の悪いコードがコミットされるのを防ぐ。

---

## よくある質問

### Q1: 暗号化はどこで行う？
**A**: `crypto_service.dart` で暗号化・復号化。
`storage_service.dart` は暗号化済みデータを保存するだけ。

### Q2: Google Drive連携はいつ実装？
**A**: フェーズ4（高度な機能）で実装。
基本機能（保存・表示・編集）が完成してから。

### Q3: 指紋認証はどう実装？
**A**: `local_auth` パッケージを使用。
`auth_service.dart` に実装。

### Q4: 有料版の機能フラグはどう管理？
**A**: `constants.dart` に定義。
`storage_service.dart` で `if (isPro)` で分岐。

---

## 注意事項

### セキュリティ
- マスターパスワードは保存しない
- 暗号化キーは `flutter_secure_storage` で保存
- Google Drive にアップロードするデータは必ず暗号化済み

### パフォーマンス
- SQLiteは大量データでも高速
- 暗号化・復号化は非同期処理（`async/await`）

### クロスプラットフォーム対応
- iOS対応時は `ios/` ディレクトリ設定が必要
- `local_auth` は iOS/Android 両対応
- Google Drive API も両OS対応

---

## 次のステップ

1. Flutter環境構築
2. プロジェクト作成（`flutter create securebox`）
3. 依存パッケージ追加（`pubspec.yaml`）
4. フェーズ1から順番に実装開始

---

**このファイルは常に最新状態に保つこと。**
**仕様変更があればこのファイルを更新。**
