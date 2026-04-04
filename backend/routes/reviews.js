const express = require('express');
const jwt = require('jsonwebtoken');
const Review = require('../models/Review');
const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

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

// Create review
router.post('/', verifyJWT, async (req, res) => {
  try {
    const { orderId, rating, comment, imageUrl } = req.body;
    
    // Fetch order to get restaurantId
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    const review = await Review.create({
      orderId,
      restaurantId: order.restaurantId,
      customerId: req.user.userId,
      customerName: req.user.email?.split('@')[0],
      rating,
      comment,
      imageUrl,
    });
    
    // Update menu item rating (optional - if review is for a specific item)
    // You might want to add itemId to review schema
    
    res.status(201).json({ success: true, review });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get reviews for an order
router.get('/order/:orderId', async (req, res) => {
  try {
    const reviews = await Review.find({ orderId: req.params.orderId });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get reviews for a restaurant
router.get('/restaurant/:restaurantId', async (req, res) => {
  try {
    const reviews = await Review.find({ restaurantId: req.params.restaurantId }).sort({ createdAt: -1 });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all reviews (for analytics)
router.get('/', async (req, res) => {
  try {
    const reviews = await Review.find().sort({ createdAt: -1 });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update review
router.put('/:id', verifyJWT, async (req, res) => {
  try {
    const { rating, comment, imageUrl } = req.body;
    
    const review = await Review.findByIdAndUpdate(
      req.params.id,
      { rating, comment, imageUrl, updatedAt: new Date() },
      { new: true }
    );
    
    res.json(review);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete review
router.delete('/:id', verifyJWT, async (req, res) => {
  try {
    const review = await Review.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Review deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
