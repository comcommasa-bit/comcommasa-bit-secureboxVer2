// api/create-checkout.js
// Stripe Checkoutセッションを作成して決済ページURLを返す

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

module.exports = async function handler(req, res) {
  // POSTのみ許可
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { userId, email } = req.body;

    // バリデーション
    if (!userId || !email) {
      return res.status(400).json({ error: 'userId and email are required' });
    }

    // Stripe Checkoutセッション作成
    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [
        {
          price: process.env.STRIPE_PRICE_ID, // 月額980円のPrice ID
          quantity: 1,
        },
      ],
      customer_email: email,
      metadata: {
        userId: userId,
      },
      success_url: `${process.env.APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.APP_URL}/cancel`,
      allow_promotion_codes: true, // クーポンコード使用可能
    });

    // 決済URLを返す
    res.status(200).json({
      sessionId: session.id,
      url: session.url,
    });
  } catch (err) {
    console.error('Error creating checkout session:', err);
    res.status(500).json({ error: err.message });
  }
}
