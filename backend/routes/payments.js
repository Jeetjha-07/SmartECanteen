const express = require('express');
const crypto = require('crypto');
const Razorpay = require('razorpay');
const jwt = require('jsonwebtoken');
const Order = require('../models/Order');
const { JWT_SECRET } = require('../config/jwt');

const router = express.Router();

// Initialize Razorpay instance
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_YOUR_TEST_KEY',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'YOUR_KEY_SECRET',
});

// Middleware to verify JWT
const verifyJWT = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

/**
 * POST /api/payments/create-order
 * Create a Razorpay order
 */
router.post('/create-order', verifyJWT, async (req, res) => {
  try {
    const { orderId, amount, currency = 'INR' } = req.body;

    if (!orderId || !amount) {
      return res
        .status(400)
        .json({ error: 'orderId and amount are required' });
    }

    console.log(`💳 Creating Razorpay order for: ${orderId}, Amount: ₹${amount / 100}`);

    // Create Razorpay order
    const options = {
      amount: Math.round(amount), // amount in paise
      currency: currency,
      receipt: orderId, // Your order ID as receipt
      notes: {
        orderId: orderId,
        customerId: req.user.userId,
      },
    };

    const razorpayOrder = await razorpay.orders.create(options);

    console.log(`✅ Razorpay order created: ${razorpayOrder.id}`);

    res.json({
      success: true,
      razorpayOrderId: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      key: process.env.RAZORPAY_KEY_ID || 'rzp_test_YOUR_TEST_KEY',
    });
  } catch (error) {
    console.error('❌ Error creating Razorpay order:', error);
    res.status(500).json({
      error: 'Failed to create payment order',
      details: error.message,
    });
  }
});

/**
 * POST /api/payments/verify-payment
 * Verify Razorpay payment signature
 */
router.post('/verify-payment', verifyJWT, async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      orderId,
    } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res
        .status(400)
        .json({ error: 'Missing payment verification details' });
    }

    console.log(`✔️ Verifying payment: ${razorpay_payment_id}`);

    // Verify signature
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'YOUR_KEY_SECRET')
      .update(body)
      .digest('hex');

    const isSignatureValid = expectedSignature === razorpay_signature;

    if (!isSignatureValid) {
      console.error('❌ Payment signature verification failed');
      return res.status(400).json({
        error: 'Payment verification failed',
        success: false,
      });
    }

    console.log(`✅ Payment signature verified!`);

    // Update order with payment details
    const order = await Order.findByIdAndUpdate(
      orderId,
      {
        paymentMethod: 'Razorpay',
        paymentStatus: 'Completed',
        razorpay_payment_id: razorpay_payment_id,
        razorpay_order_id: razorpay_order_id,
        paymentVerifiedAt: new Date(),
      },
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    console.log(`✅ Order updated with payment: ${order._id}`);

    res.json({
      success: true,
      message: 'Payment verified successfully',
      order: order,
    });
  } catch (error) {
    console.error('❌ Error verifying payment:', error);
    res.status(500).json({
      error: 'Failed to verify payment',
      details: error.message,
    });
  }
});

/**
 * GET /api/payments/payment-status/:orderId
 * Get payment status for an order
 */
router.get('/payment-status/:orderId', verifyJWT, async (req, res) => {
  try {
    const { orderId } = req.params;

    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json({
      success: true,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod,
      razorpay_payment_id: order.razorpay_payment_id,
      razorpay_order_id: order.razorpay_order_id,
    });
  } catch (error) {
    console.error('❌ Error getting payment status:', error);
    res.status(500).json({ error: 'Failed to get payment status' });
  }
});

/**
 * POST /api/payments/webhook
 * Razorpay webhook for payment notifications
 */
router.post('/webhook', async (req, res) => {
  try {
    const event = req.body.event;
    const payload = req.body.payload;

    console.log(`📬 Webhook received: ${event}`);

    switch (event) {
      case 'payment.authorized':
        console.log(`✅ Payment authorized: ${payload.payment.entity.id}`);
        break;

      case 'payment.captured':
        console.log(`✅ Payment captured: ${payload.payment.entity.id}`);
        // Update order status if needed
        break;

      case 'payment.failed':
        console.log(`❌ Payment failed: ${payload.payment.entity.id}`);
        // Update order status to failed
        break;

      case 'order.paid':
        console.log(`💰 Order paid: ${payload.order.entity.id}`);
        // Update order status
        break;

      default:
        console.log(`Unknown event: ${event}`);
    }

    res.json({ status: 'ok' });
  } catch (error) {
    console.error('❌ Error processing webhook:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

module.exports = router;
