// __tests__/stripe-webhook.test.js
// Stripe Webhook 受信 API のユニットテスト

// Stripe SDKをモック
jest.mock('stripe', () => {
  const mockConstructEvent = jest.fn();
  const mockStripe = jest.fn(() => ({
    webhooks: {
      constructEvent: mockConstructEvent,
    },
  }));
  mockStripe._mockConstructEvent = mockConstructEvent;
  return mockStripe;
});

// 環境変数を設定（テスト用）
process.env.STRIPE_SECRET_KEY = 'sk_test_dummy';
process.env.STRIPE_WEBHOOK_SECRET = 'whsec_test_dummy';

const stripe = require('stripe');
const handler = require('../api/stripe-webhook');

function createMockReqRes(method, body = '', headers = {}) {
  const req = { method, body, headers };
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

describe('POST /api/stripe-webhook', () => {
  const mockConstructEvent = stripe._mockConstructEvent;

  beforeEach(() => {
    mockConstructEvent.mockReset();
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    console.log.mockRestore();
    console.error.mockRestore();
  });

  test('POST以外のリクエストは405を返す', async () => {
    const { req, res } = createMockReqRes('GET');

    await handler(req, res);

    expect(res._status).toBe(405);
    expect(res._json).toEqual({ error: 'Method not allowed' });
  });

  test('署名検証失敗は400を返す', async () => {
    mockConstructEvent.mockImplementation(() => {
      throw new Error('Invalid signature');
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'invalid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(400);
    expect(res._json).toEqual({ error: 'Webhook Error: Invalid signature' });
  });

  test('checkout.session.completed イベントを処理', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: {
        object: {
          customer: 'cus_123',
          subscription: 'sub_123',
          customer_email: 'test@example.com',
        },
      },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'valid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({ received: true });
  });

  test('customer.subscription.created イベントを処理', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'customer.subscription.created',
      data: {
        object: {
          id: 'sub_123',
          customer: 'cus_123',
          status: 'active',
        },
      },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'valid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({ received: true });
  });

  test('customer.subscription.updated イベントを処理', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'customer.subscription.updated',
      data: {
        object: {
          id: 'sub_123',
          customer: 'cus_123',
          status: 'active',
        },
      },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'valid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({ received: true });
  });

  test('customer.subscription.deleted イベントを処理', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'customer.subscription.deleted',
      data: {
        object: {
          id: 'sub_123',
          customer: 'cus_123',
        },
      },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'valid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({ received: true });
  });

  test('invoice.payment_succeeded イベントを処理', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'invoice.payment_succeeded',
      data: {
        object: {
          customer: 'cus_123',
          subscription: 'sub_123',
          amount_paid: 980,
        },
      },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'valid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({ received: true });
  });

  test('invoice.payment_failed イベントを処理', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'invoice.payment_failed',
      data: {
        object: {
          customer: 'cus_123',
          subscription: 'sub_123',
        },
      },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'valid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({ received: true });
  });

  test('未知のイベントタイプでも200を返す', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'unknown.event.type',
      data: { object: {} },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body', {
      'stripe-signature': 'valid_sig',
    });

    await handler(req, res);

    expect(res._status).toBe(200);
    expect(res._json).toEqual({ received: true });
  });

  test('署名検証にwebhook secretが渡される', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: { object: { customer: 'cus_123', subscription: 'sub_123', customer_email: 'test@example.com' } },
    });

    const { req, res } = createMockReqRes('POST', 'raw_body_data', {
      'stripe-signature': 'sig_abc',
    });

    await handler(req, res);

    expect(mockConstructEvent).toHaveBeenCalledWith(
      'raw_body_data',
      'sig_abc',
      'whsec_test_dummy'
    );
  });
});
