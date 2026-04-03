const express = require('express');
const admin = require('firebase-admin');
const Order = require('../models/Order');

const router = express.Router();

// Middleware to verify Firebase token
const verifyToken = async (req, res, next) => {
  try {
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    if (!idToken) {
      return res.status(401).json({ error: 'No token provided' });
    }
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Create order
router.post('/', verifyToken, async (req, res) => {
  try {
    const { items, totalAmount, deliveryAddress, phoneNumber, paymentMethod, specialInstructions } = req.body;
    
    console.log('📦 Creating order for customer:', req.user.uid);
    console.log('Order data:', { totalAmount, deliveryAddress, itemCount: items?.length });
    
    // Validate required fields
    if (!items || items.length === 0) {
      return res.status(400).json({ error: 'Order must contain at least one item' });
    }
    
    if (!deliveryAddress || !phoneNumber || !totalAmount) {
      return res.status(400).json({ error: 'Missing required fields: deliveryAddress, phoneNumber, or totalAmount' });
    }
    
    const order = await Order.create({
      customerId: req.user.uid,
      customerName: req.user.email?.split('@')[0],
      customerPhone: phoneNumber,
      deliveryAddress,
      items,
      totalAmount,
      paymentMethod,
      specialInstructions,
      status: 'Pending',
    });
    
    console.log('✅ Order created successfully:', order._id);
    res.status(201).json({ success: true, order });
  } catch (error) {
    console.error('❌ Error creating order:', error);
    res.status(500).json({ error: error.message, details: error.stack });
  }
});

// Get user's orders (for customers to see their own orders)
router.get('/', verifyToken, async (req, res) => {
  try {
    const orders = await Order.find({ customerId: req.user.uid }).sort({ orderDate: -1 });
    console.log(`📋 Retrieved ${orders.length} orders for customer:`, req.user.uid);
    res.json(orders);
  } catch (error) {
    console.error('❌ Error fetching customer orders:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all orders (for restaurant dashboard to see all incoming orders)
router.get('/all/orders', verifyToken, async (req, res) => {
  try {
    const orders = await Order.find({}).sort({ orderDate: -1 });
    console.log(`📋 Retrieved ${orders.length} total orders for restaurant`);
    res.json(orders);
  } catch (error) {
    console.error('❌ Error fetching all orders:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get order by ID
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      console.warn(`⚠️ Order not found: ${req.params.id}`);
      return res.status(404).json({ error: 'Order not found' });
    }
    
    // Verify ownership
    if (order.customerId !== req.user.uid) {
      console.warn(`⚠️ Unauthorized access attempt for order ${req.params.id}`);
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    res.json(order);
  } catch (error) {
    console.error('❌ Error fetching order:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update order status (restaurant admin)
router.patch('/:id/status', verifyToken, async (req, res) => {
  try {
    const { status } = req.body;
    console.log(`🔄 Updating order ${req.params.id} status to: ${status}`);
    
    if (!['Pending', 'Preparing', 'Ready', 'Delivered', 'Cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }
    
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status, updatedAt: new Date() },
      { new: true }
    );
    
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    console.log(`✅ Order${req.params.id} status updated successfully`);
    res.json(order);
  } catch (error) {
    console.error('❌ Error updating order status:', error);
    res.status(500).json({ error: error.message });
  }
});

// Cancel order
router.patch('/:id/cancel', verifyToken, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    
    if (order.customerId !== req.user.uid) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    order.status = 'Cancelled';
    order.updatedAt = new Date();
    await order.save();
    
    res.json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete order (restaurant admin only)
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const orderId = req.params.id;
    console.log(`🗑️ Deleting order: ${orderId}`);
    
    const order = await Order.findByIdAndDelete(orderId);
    
    if (!order) {
      console.warn(`⚠️ Order not found for deletion: ${orderId}`);
      return res.status(404).json({ error: 'Order not found' });
    }
    
    console.log(`✅ Order deleted successfully: ${orderId}`);
    res.json({ success: true, message: 'Order deleted successfully', orderId });
  } catch (error) {
    console.error('❌ Error deleting order:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
