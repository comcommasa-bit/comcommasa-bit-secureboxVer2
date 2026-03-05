# SecureBox Ver2 - コードレビュー & 改善アドバイス

このファイルは、他の開発者（またはClaude）がこのリポジトリを改善する際の参考資料です。
現状の問題点と改善案をまとめています。

---

## 1. フロントエンド（Flutter）が存在しない

### 現状
- `CLAUDE-1.md` に詳細な設計書（ファイル構成、開発順序、コーディング規約など）があるが、実際のFlutterコードが一切ない
- `lib/`, `pubspec.yaml`, `android/`, `ios/` などのFlutterプロジェクトファイルが未作成
- `.gitignore` はAndroid向けだが、Flutter固有のエントリ（`.dart_tool/`, `.flutter-plugins` 等）がない

### アドバイス
- `CLAUDE-1.md` のフェーズ1～5に従ってFlutterプロジェクトを作成する
- まず `flutter create securebox` でプロジェクト雛形を生成し、このリポジトリに統合する
- 以前アーティファクトで作成したフロントコードがあれば、それをベースにする
- `.gitignore` にFlutter固有のエントリを追加する:
  ```
  .dart_tool/
  .flutter-plugins
  .flutter-plugins-dependencies
  .packages
  build/
  ```

---

## 2. バックエンド: CommonJS と ESM の混在

### 現状（`api/create-checkout.js`, `api/stripe-webhook.js` 両方）
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);  // CommonJS
export default async function handler(req, res) {                 // ESM
```

### 問題
- `require` と `export default` を同じファイルで使っている
- Vercelの `@vercel/node` ランタイムは自動変換してくれるため動く可能性はあるが、コードとしては不正
- 他の環境（ローカルテスト、別のホスティング）では動かない

### アドバイス
どちらかに統一する。ESMに統一する場合:
```javascript
import Stripe from 'stripe';
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export default async function handler(req, res) { ... }
```
CommonJSに統一する場合:
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

module.exports = async function handler(req, res) { ... };
```

---

## 3. バックエンド: DB連携が全て未実装（TODO状態）

### 現状（`api/stripe-webhook.js`）
全てのハンドラ関数が `console.log` のみで、実際のデータベース更新がない。
```javascript
// TODO: データベースにユーザー情報を保存
// await updateUserPlan(customerId, 'pro');
```

### アドバイス
- SupabaseまたはFirebaseのどちらを使うか決定する
- `BACKEND-README.md` にサンプルコードがあるので、それを参考に実装する
- 優先度: `handleCheckoutCompleted` > `handleSubscriptionDeleted` > その他
- DB連携を実装するなら、`package.json` に `@supabase/supabase-js` または `firebase-admin` を追加する
- `.env.example` にDB関連の環境変数も追加する

---

## 4. セキュリティの問題

### 4-1. CORS設定がない

### 現状
`api/create-checkout.js` にCORS制御がなく、どのドメインからでもAPIを呼べる。

### アドバイス
```javascript
// レスポンスヘッダーにCORSを設定
res.setHeader('Access-Control-Allow-Origin', process.env.APP_URL);
res.setHeader('Access-Control-Allow-Methods', 'POST');
res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

// OPTIONSリクエスト（プリフライト）対応
if (req.method === 'OPTIONS') {
  return res.status(200).end();
}
```

### 4-2. 認証・認可がない

### 現状
`create-checkout.js` の `userId` は `req.body` からそのまま受け取っており、認証トークンの検証がない。
誰でも任意の `userId` でチェックアウトセッションを作成できる。

### アドバイス
- Firebase AuthまたはSupabase Authのトークン検証を追加する
- `Authorization` ヘッダーからBearerトークンを取得し、サーバーサイドで検証する
- 検証済みのユーザーIDを使用する（リクエストボディのuserIdを信用しない）

### 4-3. レート制限がない

### アドバイス
- Vercelの場合、`vercel.json` でレート制限を設定するか、ミドルウェアで制御する
- 簡易的にはメモリベースのレート制限（ただしサーバーレスでは効果が限定的）
- 本格的にはUpstash Redisなどを使ったレート制限を検討

### 4-4. エラーメッセージの漏洩

### 現状（`api/create-checkout.js:46`）
```javascript
res.status(500).json({ error: err.message });
```

### アドバイス
- 本番環境ではStripeの内部エラーメッセージをそのままクライアントに返さない
- ログには詳細を記録し、クライアントには汎用メッセージを返す:
```javascript
console.error('Error creating checkout session:', err);
res.status(500).json({ error: 'Failed to create checkout session' });
```

---

## 5. Webhook の raw body 問題

### 現状
`stripe-webhook.js` で `stripe.webhooks.constructEvent(req.body, sig, webhookSecret)` を呼んでいるが、Vercelはデフォルトでリクエストボディをパースする。

### 問題
Stripe Webhookの署名検証には**生のリクエストボディ（raw body）**が必要。パース済みのJSONオブジェクトでは署名検証に失敗する。

### アドバイス
`vercel.json` に以下を追加してraw bodyを保持する:
```json
{
  "functions": {
    "api/stripe-webhook.js": {
      "maxDuration": 10
    }
  }
}
```
また、コード側で `req.rawBody` または `micro` パッケージの `buffer()` を使用する:
```javascript
import { buffer } from 'micro';

export const config = {
  api: {
    bodyParser: false,
  },
};

// ハンドラ内で
const buf = await buffer(req);
const event = stripe.webhooks.constructEvent(buf, sig, webhookSecret);
```
**これは実装しないとWebhookが動かない重要な問題。**

---

## 6. package.json の改善

### 現状
- `"main": "index.js"` だが `index.js` は存在しない
- テストスクリプトがない
- lint設定がない

### アドバイス
```json
{
  "main": "api/create-checkout.js",
  "scripts": {
    "dev": "vercel dev",
    "deploy": "vercel --prod",
    "lint": "eslint api/",
    "test": "jest"
  }
}
```

---

## 7. README.md が空

### 現状
```markdown
# comcommasa-bit-secureboxVer2
secureboxVer2
```

### アドバイス
- プロジェクト概要、セットアップ手順、技術スタックを記載する
- `BACKEND-README.md` の内容の要約を含める
- フロントエンド（Flutter）のセットアップ手順も追加する

---

## 8. 環境変数・設定

### .env.example への追加が必要
DB連携を実装する場合:
```
# Supabaseの場合
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJxxxxx

# Firebaseの場合
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@xxx.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nxxxxx\n-----END PRIVATE KEY-----"
```

---

## 優先度まとめ

| 優先度 | 項目 | 理由 |
|--------|------|------|
| **高** | Webhook raw body問題 (#5) | これがないとWebhookが動かない |
| **高** | CommonJS/ESM混在 (#2) | コードの正確性 |
| **高** | CORS設定 (#4-1) | Flutterアプリから呼べない |
| **中** | 認証追加 (#4-2) | セキュリティ上重要 |
| **中** | DB連携 (#3) | 課金機能として必須 |
| **中** | エラーメッセージ (#4-4) | 情報漏洩防止 |
| **低** | Flutter実装 (#1) | 別途大きなタスク |
| **低** | README更新 (#7) | 開発に直接影響しない |
| **低** | package.json修正 (#6) | 動作に直接影響しない |

---

## フロントエンド開発について

フロントエンド（Flutter）は `CLAUDE-1.md` に詳細な設計書がある。

### UI参考資料
**`reference/securebox-list.html`** に完全なUIモックアップがある。Flutter実装時は必ずこのファイルを参照すること：
- ダークテーマの配色（CSS変数）
- リスト画面・詳細画面・編集画面の3画面構成
- カテゴリ別表示、FAB、トースト通知のUI仕様
- タップでコピー/長押しで表示のインタラクション
- SVGアイコンのデザイン（盾+鍵のロゴ等）

このHTMLをブラウザで開けば、完成イメージを確認できる。

フロントとバックエンドの接続ポイント:
- `api/create-checkout` を呼ぶのはFlutter側の課金画面
- Webhookの結果（プラン状態）はDBを経由してFlutter側で取得する
- DB（Supabase/Firebase）の選択がフロント・バック両方に影響するので、先に決定すべき

---

*このファイルは 2026-03-05 に作成。修正が完了した項目は都度更新すること。*
