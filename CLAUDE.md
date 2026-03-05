# SecureBox - AI向け引き継ぎファイル

## 詳細設計書

詳細な設計・仕様は `CLAUDE-1.md` を参照すること。

## 現在の進捗状況（2026-03-05 時点）

### 完了済み

- **フェーズ1（基盤）**: constants, key_model, crypto_service, toast, validators, helpers
- **フェーズ2（コア機能）**: storage_service (SQLite CRUD), search_service
- **フェーズ3（UI）**: list_screen, detail_screen, edit_screen, key_list_item, key_detail_card
- **フェーズ4（高度な機能）**: auth_service（生体認証）, backup_service（Google Drive連携）
- **フェーズ5（統合）**: main.dart - 認証画面とアプリフロー統合
- **テスト**: 48件のユニットテスト作成・全パス
- **コードレビュー**: REVIEW.md に改善提案を記載
- **UI参考**: reference/ にHTML版UIリファレンスを配置
- **アプリアイコン**: 猫+鍵デザインの画像を `assets/icon/app-icon.png` に配置
- **flutter_launcher_icons**: pubspec.yaml に設定追加済み（未実行）

### 未完了・次のステップ

- `flutter pub get` → `dart run flutter_launcher_icons` でアイコン生成
- 実機テスト・動作確認
- REVIEW.md の改善提案の適用（任意）
- 有料版機能（Stripe決済、AI機能）は未実装

## プロジェクト構造

- `lib/` - Flutterアプリ本体
- `api/` - バックエンドAPI（Stripe決済用、Vercelデプロイ）
- `test/` - ユニットテスト
- `assets/icon/` - アプリアイコン画像
- `reference/` - UI参考HTML

## 重要な技術情報

- Flutter 3.x (Dart), Android優先
- AES-256-GCM + PBKDF2（60万回）で暗号化
- SQLiteでローカル保存
- 無料版: 10個まで / 有料版: 無制限（月額980円）
