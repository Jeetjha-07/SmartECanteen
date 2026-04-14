const express = require('express');
const jwt = require('jsonwebtoken');
const Order = require('../models/Order');
const TimeSlot = require('../models/TimeSlot');
const { JWT_SECRET } = require('../config/jwt');

const router = express.Router();

// Middleware to verify JWT token
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
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Create order
router.post('/', verifyJWT, async (req, res) => {
  try {
    const { items, totalAmount, deliveryAddress, phoneNumber, paymentMethod, specialInstructions, restaurantId, timeSlotId, couponCode } = req.body;
    
    console.log('\n📦 CREATE ORDER - Request received');
    console.log('   Customer: ' + req.user.userId);
    console.log('   restaurantId (from body): "' + restaurantId + '" (type: ' + typeof restaurantId + ')');
    console.log('   Items: ' + items?.length);
    console.log('   Amount: ₹' + totalAmount);
    
    // Validate required fields
    if (!items || items.length === 0) {
      return res.status(400).json({ error: 'Order must contain at least one item' });
    }
    
    if (!deliveryAddress || !phoneNumber || !totalAmount) {
      return res.status(400).json({ error: 'Missing required fields: deliveryAddress, phoneNumber, or totalAmount' });
    }

    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    // If timeSlotId is provided, check if slot has availability
    if (timeSlotId) {
      const timeSlot = await TimeSlot.findById(timeSlotId);
      
      if (!timeSlot) {
        return res.status(404).json({ error: 'Time slot not found' });
      }

      if (timeSlot.currentOrders >= timeSlot.capacity) {
        return res.status(400).json({ error: 'Time slot is full. Please select another slot.' });
      }

      if (!timeSlot.isAvailable) {
        return res.status(400).json({ error: 'This time slot is currently unavailable' });
      }
    }
    
    const order = await Order.create({
      customerId: req.user.userId,
      customerName: req.user.email?.split('@')[0],
      customerPhone: phoneNumber,
      deliveryAddress,
      restaurantId,
      items,
      totalAmount,
      paymentMethod,
      specialInstructions,
      timeSlotId,
      couponCode,
      status: 'Pending',
    });

    console.log('   ✅ Saved to DB - Order.' + order._id);
    console.log('   ✅ Saved restaurantId: "' + order.restaurantId + '"');

    // If timeSlotId is provided, increment currentOrders
    if (timeSlotId) {
      const timeSlot = await TimeSlot.findById(timeSlotId);
      if (timeSlot) {
        timeSlot.currentOrders += 1;
        await timeSlot.save();
        console.log(`   📊 Updated time slot ${timeSlotId}: ${timeSlot.currentOrders}/${timeSlot.capacity} orders`);
      }
    }

    // Update coupon usage tracking
    if (couponCode) {
      try {
        const Coupon = require('../models/Coupon');
        const coupon = await Coupon.findOne({
          code: couponCode.toUpperCase(),
          restaurantId: restaurantId,
        });

        if (coupon) {
          coupon.usedCount = (coupon.usedCount || 0) + 1;
          coupon.usedBy.push({
            userId: req.user.userId,
            usedAt: new Date(),
            orderId: order._id,
          });
          await coupon.save();
          console.log(`   💰 Updated coupon ${couponCode}: ${coupon.usedCount}/${coupon.maxUses || '∞'} uses`);
        }
      } catch (couponError) {
        console.warn('⚠️  Coupon usage update failed (order still created):', couponError.message);
        // Don't fail order if coupon tracking fails
      }
    }
    
    console.log('✅ Order created successfully:', order._id);
    res.status(201).json({ success: true, order });
  } catch (error) {
    console.error('❌ Error creating order:', error);
    res.status(500).json({ error: error.message, details: error.stack });
  }
});

// Get user's orders (for customers to see their own orders)
router.get('/', verifyJWT, async (req, res) => {
  try {
    const orders = await Order.find({ customerId: req.user.userId }).sort({ orderDate: -1 });
    console.log(`📋 Retrieved ${orders.length} orders for customer:`, req.user.userId);
    res.json(orders);
  } catch (error) {
    console.error('❌ Error fetching customer orders:', error);
    res.status(500).json({ error: error.message });
  }
});

// DEBUG: Get diagnostics about orders for this restaurant
router.get('/debug/stats', verifyJWT, async (req, res) => {
  try {
    if (req.user.role !== 'restaurant') {
      return res.status(403).json({ error: 'Only restaurants can access this endpoint' });
    }

    const restaurantIdString = req.user.userId.toString();
    const allOrders = await Order.find({});
    const matchingOrders = await Order.find({ restaurantId: restaurantIdString });

    const User = require('../models/User');
    const user = await User.findById(req.user.userId);

    return res.json({
      debug_info: {
        user_id: req.user.userId + '',
        user_id_type: typeof req.user.userId,
        user_restaurantId_from_jwt: req.user.restaurantId,
        user_restaurantId_from_db: user?.restaurantId,
        query_used: restaurantIdString,
      },
      stats: {
        total_orders_in_db: allOrders.length,
        orders_matching_this_restaurant: matchingOrders.length,
      },
      sample_orders_in_db: allOrders.slice(0, 5).map(o => ({
        id: o._id + '',
        restaurantId: o.restaurantId,
        customerId: o.customerId,
        totalAmount: o.totalAmount,
        status: o.status,
      })),
      your_orders: matchingOrders.slice(0, 5).map(o => ({
        id: o._id + '',
        restaurantId: o.restaurantId,
        totalAmount: o.totalAmount,
        status: o.status,
      })),
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// Get all orders (for restaurant dashboard to see only their incoming orders)
router.get('/all/orders', verifyJWT, async (req, res) => {
  try {
    // Only allow restaurants to see their own orders
    if (req.user.role !== 'restaurant') {
      return res.status(403).json({ error: 'Only restaurants can access this endpoint' });
    }

    // Get orders only for this restaurant using userId as restaurantId (matching how orders are created)
    // Convert userId to string to match the String type in Order schema
    const restaurantIdString = req.user.userId.toString();
    
    console.log('\n📋 Orders.get(/all/orders) - Authenticated Request');
    console.log('   User email: ' + req.user.email);
    console.log('   User role: ' + req.user.role);
    console.log('   req.user.userId: ' + req.user.userId + ' (type: ' + typeof req.user.userId + ')');
    console.log('   restaurantIdString: ' + restaurantIdString + ' (type: ' + typeof restaurantIdString + ')');
    
    const orders = await Order.find({ restaurantId: restaurantIdString }).sort({ orderDate: -1 });
    
    console.log('   Query result: Found ' + orders.length + ' orders');
    if (orders.length > 0) {
      console.log('   Sample orders:');
      orders.slice(0, 3).forEach((o, idx) => {
        console.log('   [' + (idx + 1) + '] Order ' + o._id + ': restaurantId="' + o.restaurantId + '" | Amount: ₹' + o.totalAmount + ' | Status: ' + o.status);
      });
    } else {
      console.log('   ⚠️ WARNING: No orders found for this restaurant!');
      console.log('   Checking all orders in database...');
      const allOrders = await Order.find({}).sort({ orderDate: -1 });
      console.log('   Total orders in DB: ' + allOrders.length);
      if (allOrders.length > 0) {
        console.log('   Sample of ALL orders in DB:');
        allOrders.slice(0, 5).forEach((o, idx) => {
          console.log('   [' + (idx + 1) + '] restaurantId="' + o.restaurantId + '" (looking for "' + restaurantIdString + '")');
        });
      }
    }
    
    res.json(orders);
  } catch (error) {
    console.error('❌ Error fetching restaurant orders:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get order by ID
router.get('/:id', verifyJWT, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      console.warn(`⚠️ Order not found: ${req.params.id}`);
      return res.status(404).json({ error: 'Order not found' });
    }
    
    // Verify ownership
    if (order.customerId !== req.user.userId) {
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
router.patch('/:id/status', verifyJWT, async (req, res) => {
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
router.patch('/:id/cancel', verifyJWT, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    
    if (order.customerId !== req.user.userId) {
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
router.delete('/:id', verifyJWT, async (req, res) => {
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
