const express = require('express');
const crypto = require('crypto');
const Razorpay = require('razorpay');
const jwt = require('jsonwebtoken');
const Order = require('../models/Order');
const { JWT_SECRET } = require('../config/jwt');

const router = express.Router();

// ✅ Validate Razorpay credentials on startup
const validateRazorpayCredentials = () => {
  const keyId = process.env.RAZORPAY_KEY_ID?.trim();
  const keySecret = process.env.RAZORPAY_KEY_SECRET?.trim();

  console.log('🔐 Razorpay Credentials Validation:');
  console.log(`   Key ID: ${keyId ? '✓ Present' : '❌ MISSING'} (${keyId?.length || 0} chars)`);
  console.log(`   Key Secret: ${keySecret ? '✓ Present' : '❌ MISSING'} (${keySecret?.length || 0} chars)`);

  if (!keyId || !keySecret) {
    console.error('❌ CRITICAL: Razorpay credentials not found in environment variables!');
    console.error('   Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in .env file');
    console.error('   Get your keys from: https://dashboard.razorpay.com/app/keys');
  } else if (keyId === 'rzp_test_YOUR_TEST_KEY' || keySecret === 'YOUR_KEY_SECRET') {
    console.error('❌ CRITICAL: Razorpay credentials are still using placeholder values!');
    console.error('   Replace with actual credentials from https://dashboard.razorpay.com/app/keys');
  } else if (keySecret.length < 30) {
    console.warn('⚠️  WARNING: KEY_SECRET seems too short. Valid secrets are typically 40+ characters');
  } else {
    console.log('✅ Razorpay credentials appear valid');
  }
};

// Initialize Razorpay instance
let razorpay;
try {
  validateRazorpayCredentials();
  
  const keyId = process.env.RAZORPAY_KEY_ID?.trim();
  const keySecret = process.env.RAZORPAY_KEY_SECRET?.trim();
  
  if (keyId && keySecret && keyId !== 'rzp_test_YOUR_TEST_KEY' && keySecret !== 'YOUR_KEY_SECRET') {
    razorpay = new Razorpay({
      key_id: keyId,
      key_secret: keySecret,
    });
    console.log('✅ Razorpay SDK initialized successfully');
  } else {
    console.error('❌ Cannot initialize Razorpay - invalid or missing credentials');
    razorpay = null;
  }
} catch (error) {
  console.error('❌ Error initializing Razorpay:', error.message);
  razorpay = null;
}

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
    // Check if Razorpay is initialized
    if (!razorpay) {
      console.error('❌ Razorpay SDK not initialized - invalid credentials');
      return res.status(500).json({
        error: 'Payment gateway not configured',
        details: 'Razorpay credentials are missing or invalid. Please contact support.',
      });
    }

    const { orderId, amount, currency = 'INR' } = req.body;

    if (!orderId || !amount) {
      return res
        .status(400)
        .json({ error: 'orderId and amount are required' });
    }

    console.log(`💳 Creating Razorpay order for: ${orderId}, Amount: ₹${amount / 100}`);
    console.log(`   Currency: ${currency}`);
    console.log(`   User ID: ${req.user?.userId}`);

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

    console.log(`   Sending to Razorpay API with options:`, JSON.stringify(options, null, 2));

    const razorpayOrder = await razorpay.orders.create(options);

    console.log(`✅ Razorpay order created: ${razorpayOrder.id}`);

    res.json({
      success: true,
      razorpayOrderId: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      key: process.env.RAZORPAY_KEY_ID?.trim() || 'rzp_test_YOUR_TEST_KEY',
    });
  } catch (error) {
    console.error('❌ Error creating Razorpay order:');
    console.error(`   Status Code: ${error.statusCode}`);
    console.error(`   Error Message: ${error.message}`);
    console.error(`   Error Description: ${error.error?.description || 'N/A'}`);
    console.error(`   Full Error:`, error);

    // Provide specific error messages for common issues
    const statusCode = error.statusCode || 500;
    let userMessage = 'Failed to create payment order';

    if (statusCode === 401 || error.message?.includes('Authentication')) {
      userMessage = 'Payment gateway authentication failed. Please check API credentials.';
      console.error('🔐 This usually means: Invalid API Key ID or Secret');
    } else if (statusCode === 400 || error.message?.includes('BAD_REQUEST')) {
      userMessage = 'Invalid payment parameters. ' + (error.error?.description || '');
    } else if (statusCode === 429) {
      userMessage = 'Too many requests. Please try again later.';
    }

    res.status(statusCode === 401 ? 401 : 500).json({
      error: userMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
      statusCode: error.statusCode,
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

    // Verify signature using the correct key secret
    const keySecret = process.env.RAZORPAY_KEY_SECRET?.trim();
    if (!keySecret || keySecret === 'YOUR_KEY_SECRET') {
      console.error('❌ Cannot verify signature - invalid KEY_SECRET');
      return res.status(500).json({
        error: 'Payment verification failed',
        details: 'Gateway configuration error',
        success: false,
      });
    }

    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac('sha256', keySecret)
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

    console.log(`   Looking for order with receipt: ${orderId}`);

    // Try to find order by receipt field
    let order = await Order.findOne({ receipt: orderId });

    if (!order) {
      // Also try to find by razorpay_order_id in case it was already created
      order = await Order.findOne({ razorpay_order_id: razorpay_order_id });
    }

    if (!order) {
      console.log(`   ⚠️  Order not found - creating new order with payment details`);
      
      // If order doesn't exist, create it with payment details
      order = await Order.create({
        razorpay_payment_id: razorpay_payment_id,
        razorpay_order_id: razorpay_order_id,
        receipt: orderId,
        paymentMethod: 'Razorpay',
        paymentStatus: 'Completed',
        paymentVerifiedAt: new Date(),
      });

      console.log(`   ✅ Order created with ID: ${order._id}`);
    } else {
      console.log(`   ✅ Order found, updating payment details...`);
      
      // Update existing order with payment details
      order = await Order.findByIdAndUpdate(
        order._id,
        {
          paymentMethod: 'Razorpay',
          paymentStatus: 'Completed',
          razorpay_payment_id: razorpay_payment_id,
          razorpay_order_id: razorpay_order_id,
          paymentVerifiedAt: new Date(),
        },
        { new: true }
      );
    }

    if (!order) {
      return res.status(404).json({ error: 'Order creation/update failed' });
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
