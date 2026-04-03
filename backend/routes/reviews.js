const express = require('express');
const admin = require('firebase-admin');
const Review = require('../models/Review');
const MenuItem = require('../models/MenuItem');

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

// Create review
router.post('/', verifyToken, async (req, res) => {
  try {
    const { orderId, rating, comment, imageUrl } = req.body;
    
    const review = await Review.create({
      orderId,
      customerId: req.user.uid,
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
router.put('/:id', verifyToken, async (req, res) => {
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
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const review = await Review.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Review deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
