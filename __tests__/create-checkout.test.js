// __tests__/create-checkout.test.js
// Stripe Checkout セッション作成 API のユニットテスト

// Stripe SDKをモック
jest.mock('stripe', () => {
  const mockCreate = jest.fn();
  const mockStripe = jest.fn(() => ({
    checkout: {
      sessions: {
        create: mockCreate,
      },
    },
  }));
  mockStripe._mockCreate = mockCreate;
  return mockStripe;
});

// 環境変数を設定（テスト用）
process.env.STRIPE_SECRET_KEY = 'sk_test_dummy';
process.env.STRIPE_PRICE_ID = 'price_test_dummy';
process.env.APP_URL = 'https://test-app.example.com';

const stripe = require('stripe');
const handler = require('../api/create-checkout');

function createMockReqRes(method, body = {}) {
  const req = { method, body };
  const res = {
    _status: null,
    _json: null,
    status(code) {
      this._status = code;
      return this;
    },
    json(data) {
      this._json = data;
      return this;
    },
  };
  return { req, res };
}

describe('POST /api/create-checkout', () => {
  const mockCreate = stripe._mockCreate;

  beforeEach(() => {
    mockCreate.mockReset();
  });

  test('POST以外のリクエストは405を返す', async () => {
    const { req, res } = createMockReqRes('GET');

    await handler(req, res);

    expect(res._status).toBe(405);
    expect(res._json).toEqual({ error: 'Method not allowed' });
  });

  test('userId未指定は400を返す', async () => {
    const { req, res } = createMockReqRes('POST', { email: 'test@example.com' });

    await handler(req, res);

    expect(res._status).toBe(400);
    expect(res._json).toEqual({ error: 'userId and email are required' });
  });

  test('email未指定は400を返す', async () => {
    const { req, res } = createMockReqRes('POST', { userId: 'user_123' });

    await handler(req, res);

    expect(res._status).toBe(400);
    expect(res._json).toEqual({ error: 'userId and email are required' });
  });

  test('正常なリクエストでCheckoutセッションを作成', async () => {
    mockCreate.mockResolvedValue({
      id: 'cs_test_abc123',
      url: 'https://checkout.stripe.com/pay/cs_test_abc123',
    });

    const { req, res } = createMockReqRes('POST', {
      userId: 'user_123',
      email: 'test@example.com',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({
      sessionId: 'cs_test_abc123',
      url: 'https://checkout.stripe.com/pay/cs_test_abc123',
    });

    // Stripe APIに正しいパラメータが渡されたか確認
    expect(mockCreate).toHaveBeenCalledWith({
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{ price: 'price_test_dummy', quantity: 1 }],
      customer_email: 'test@example.com',
      metadata: { userId: 'user_123' },
      success_url: 'https://test-app.example.com/success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: 'https://test-app.example.com/cancel',
      allow_promotion_codes: true,
    });
  });

  test('Stripe APIエラー時は500を返す', async () => {
    mockCreate.mockRejectedValue(new Error('Stripe API error'));

    const { req, res } = createMockReqRes('POST', {
      userId: 'user_123',
      email: 'test@example.com',
    });

    await handler(req, res);

    expect(res._status).toBe(500);
    expect(res._json).toEqual({ error: 'Stripe API error' });
  });
});
