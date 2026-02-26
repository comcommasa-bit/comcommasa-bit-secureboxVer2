# SecureBox Backend API

Stripe決済とサブスクリプション管理のためのバックエンドAPI。

---

## 構成

```
api/
├── stripe-webhook.js      # Stripe Webhook受信
├── create-checkout.js     # 決済ページ作成
vercel.json                # Vercel設定
package.json               # 依存関係
.env.example               # 環境変数サンプル
```

---

## セットアップ

### 1. リポジトリにファイル追加

```bash
# これらのファイルをリポジトリにアップロード
api/stripe-webhook.js
api/create-checkout.js
vercel.json
package.json
.env.example
```

### 2. Stripe設定

#### 商品・価格作成
1. [Stripeダッシュボード](https://dashboard.stripe.com/test/products) にアクセス
2. 「商品を追加」をクリック
3. 商品情報入力:
   - 名前: SecureBox Pro
   - 説明: 無制限保存・AI機能
4. 価格情報入力:
   - 金額: 980円
   - 請求: 定期的
   - 請求期間: 月次
5. 保存して Price ID (`price_xxxxx`) をコピー

#### API Key取得
1. [APIキー](https://dashboard.stripe.com/apikeys) にアクセス
2. 「Secret key」をコピー (`sk_test_xxxxx`)

#### Webhook設定
1. [Webhooks](https://dashboard.stripe.com/test/webhooks) にアクセス
2. 「エンドポイントを追加」をクリック
3. エンドポイントURL: `https://your-domain.vercel.app/api/stripe-webhook`
4. イベント選択:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. 保存して Webhook Secret (`whsec_xxxxx`) をコピー

### 3. Vercelデプロイ

#### Vercel CLI インストール
```bash
npm install -g vercel
```

#### ログイン
```bash
vercel login
```

#### デプロイ
```bash
vercel --prod
```

#### 環境変数設定
Vercelダッシュボード > Settings > Environment Variables で設定:

```
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxx
STRIPE_PRICE_ID=price_xxxxxxxxxxxxxxxxxxxxx
APP_URL=https://your-app-domain.com
```

---

## API仕様

### POST /api/create-checkout

決済ページURLを作成。

**リクエスト:**
```json
{
  "userId": "user123",
  "email": "user@example.com"
}
```

**レスポンス:**
```json
{
  "sessionId": "cs_test_xxxxx",
  "url": "https://checkout.stripe.com/c/pay/cs_test_xxxxx"
}
```

**使用例（Flutter）:**
```dart
final response = await http.post(
  Uri.parse('https://your-api.vercel.app/api/create-checkout'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'userId': currentUser.id,
    'email': currentUser.email,
  }),
);

final data = jsonDecode(response.body);
final checkoutUrl = data['url'];

// ブラウザで開く
await launchUrl(Uri.parse(checkoutUrl));
```

---

### POST /api/stripe-webhook

Stripeからのイベントを受信（自動）。

**処理されるイベント:**
- `checkout.session.completed` - 新規課金成功
- `customer.subscription.created` - サブスクリプション作成
- `customer.subscription.updated` - サブスクリプション更新
- `customer.subscription.deleted` - サブスクリプション解約
- `invoice.payment_succeeded` - 定期支払い成功
- `invoice.payment_failed` - 定期支払い失敗

---

## データベース連携

### TODO
現在はコンソールログのみ。実際の運用にはデータベース連携が必要。

**オプション1: Supabase**
```javascript
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

async function updateUserPlan(customerId, plan) {
  await supabase
    .from('users')
    .update({ plan: plan })
    .eq('stripe_customer_id', customerId);
}
```

**オプション2: Firebase**
```javascript
const admin = require('firebase-admin');
admin.initializeApp();

async function updateUserPlan(customerId, plan) {
  await admin.firestore()
    .collection('users')
    .doc(customerId)
    .update({ plan: plan });
}
```

---

## テスト

### Stripe CLIでローカルテスト

#### CLI インストール
```bash
brew install stripe/stripe-cli/stripe
```

#### ログイン
```bash
stripe login
```

#### Webhook転送
```bash
stripe listen --forward-to localhost:3000/api/stripe-webhook
```

#### テストイベント送信
```bash
stripe trigger checkout.session.completed
```

---

## トラブルシューティング

### Webhook署名エラー
- Webhook Secretが正しいか確認
- Vercelの環境変数が設定されているか確認

### 決済ページが開かない
- APP_URLが正しいか確認
- STRIPE_PRICE_IDが正しいか確認

### サブスクリプションが反映されない
- Webhookエンドポイントが正しいか確認
- Stripeダッシュボード > Webhooksでイベント履歴を確認

---

## セキュリティ

- Secret Keyは絶対に公開しない
- Webhook Secretで署名検証
- 環境変数はVercelで管理

---

## 本番環境への移行

### テストモード → 本番モード

1. Stripeダッシュボードを本番モードに切り替え
2. 本番用のAPI Key・Price ID・Webhook Secretを取得
3. Vercelの環境変数を本番用に更新
4. 再デプロイ

---

## 次のステップ

1. データベース連携（Supabase or Firebase）
2. ユーザー認証連携
3. カスタマーポータル実装（サブスク管理画面）
4. メール通知機能

---

**このファイルは CLAUDE.md と一緒にリポジトリで管理。**
