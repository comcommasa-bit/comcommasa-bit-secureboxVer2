// api/stripe-webhook.js
// Stripe Webhookを受信してユーザーのプラン状態を更新

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

export default async function handler(req, res) {
  // POSTのみ許可
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    // Stripeからの署名を検証
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).json({ error: `Webhook Error: ${err.message}` });
  }

  // イベント処理
  try {
    switch (event.type) {
      case 'checkout.session.completed':
        // 新規課金成功
        await handleCheckoutCompleted(event.data.object);
        break;

      case 'customer.subscription.created':
        // サブスクリプション作成
        await handleSubscriptionCreated(event.data.object);
        break;

      case 'customer.subscription.updated':
        // サブスクリプション更新（プラン変更等）
        await handleSubscriptionUpdated(event.data.object);
        break;

      case 'customer.subscription.deleted':
        // サブスクリプション解約
        await handleSubscriptionDeleted(event.data.object);
        break;

      case 'invoice.payment_succeeded':
        // 定期支払い成功
        await handlePaymentSucceeded(event.data.object);
        break;

      case 'invoice.payment_failed':
        // 定期支払い失敗
        await handlePaymentFailed(event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.status(200).json({ received: true });
  } catch (err) {
    console.error('Error processing webhook:', err);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
}

/**
 * チェックアウト完了時の処理
 */
async function handleCheckoutCompleted(session) {
  const customerId = session.customer;
  const subscriptionId = session.subscription;
  
  // ここでデータベース更新
  // 例: Supabase, Firebase等に保存
  console.log('Checkout completed:', {
    customerId,
    subscriptionId,
    email: session.customer_email,
  });

  // TODO: データベースにユーザー情報を保存
  // await updateUserPlan(customerId, 'pro');
}

/**
 * サブスクリプション作成時の処理
 */
async function handleSubscriptionCreated(subscription) {
  const customerId = subscription.customer;
  const status = subscription.status;

  console.log('Subscription created:', {
    customerId,
    subscriptionId: subscription.id,
    status,
  });

  // TODO: データベース更新
  // await updateUserPlan(customerId, 'pro');
}

/**
 * サブスクリプション更新時の処理
 */
async function handleSubscriptionUpdated(subscription) {
  const customerId = subscription.customer;
  const status = subscription.status;

  console.log('Subscription updated:', {
    customerId,
    subscriptionId: subscription.id,
    status,
  });

  // ステータスに応じて処理
  if (status === 'active') {
    // TODO: プランをProに更新
    // await updateUserPlan(customerId, 'pro');
  } else if (status === 'canceled' || status === 'unpaid') {
    // TODO: プランをFreeに戻す
    // await updateUserPlan(customerId, 'free');
  }
}

/**
 * サブスクリプション解約時の処理
 */
async function handleSubscriptionDeleted(subscription) {
  const customerId = subscription.customer;

  console.log('Subscription deleted:', {
    customerId,
    subscriptionId: subscription.id,
  });

  // TODO: プランをFreeに戻す
  // await updateUserPlan(customerId, 'free');
}

/**
 * 支払い成功時の処理
 */
async function handlePaymentSucceeded(invoice) {
  const customerId = invoice.customer;
  const subscriptionId = invoice.subscription;

  console.log('Payment succeeded:', {
    customerId,
    subscriptionId,
    amountPaid: invoice.amount_paid,
  });

  // TODO: 支払い履歴を記録
  // await recordPayment(customerId, invoice);
}

/**
 * 支払い失敗時の処理
 */
async function handlePaymentFailed(invoice) {
  const customerId = invoice.customer;
  const subscriptionId = invoice.subscription;

  console.log('Payment failed:', {
    customerId,
    subscriptionId,
  });

  // TODO: ユーザーに通知
  // await notifyPaymentFailed(customerId);
}
