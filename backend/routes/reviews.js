const express = require('express');
const jwt = require('jsonwebtoken');
const Review = require('../models/Review');
const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');
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

// ⚠️ IMPORTANT: Specific routes MUST come before generic /:id routes!

// DEBUG: Check all reviews in database (MUST be before generic routes)
router.get('/debug/all-reviews', async (req, res) => {
  try {
    console.log('\n🔍 DEBUG: Fetching ALL reviews from database');
    
    const allReviews = await Review.find({}).sort({ createdAt: -1 });
    
    console.log(`📊 Total reviews in database: ${allReviews.length}`);
    
    if (allReviews.length === 0) {
      console.log('   Database is empty - no reviews found');
      return res.json({
        message: 'No reviews in database',
        count: 0,
        reviews: []
      });
    }
    
    console.log('   Detailed review information:');
    const reviewDetails = allReviews.map((r, idx) => {
      console.log(`   [${idx + 1}] Review Details:`);
      console.log(`       _id: ${r._id}`);
      console.log(`       orderId: ${r.orderId}`);
      console.log(`       restaurantId: ${r.restaurantId}`);
      console.log(`       customerId: ${r.customerId}`);
      console.log(`       rating: ${r.rating}`);
      console.log(`       createdAt: ${r.createdAt}`);
      
      return {
        _id: r._id.toString(),
        orderId: r.orderId?.toString() || 'N/A',
        restaurantId: r.restaurantId,
        customerId: r.customerId,
        rating: r.rating,
        createdAt: r.createdAt,
        comment: r.comment?.substring(0, 50) + '...' || 'N/A'
      };
    });
    
    res.json({
      message: `Found ${allReviews.length} reviews`,
      count: allReviews.length,
      reviews: reviewDetails
    });
  } catch (error) {
    console.error('❌ DEBUG: Error fetching reviews:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get reviews for an order (specific path)
router.get('/order/:orderId', async (req, res) => {
  try {
    const reviews = await Review.find({ orderId: req.params.orderId });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get reviews for authenticated restaurant (using JWT - MUST be before generic :restaurantId route)
router.get('/restaurant/my/reviews', verifyJWT, async (req, res) => {
  try {
    console.log('\n📋 AUTHENTICATED: Fetching reviews for restaurant:', req.user.userId);
    
    // Convert userId to string to match the String type in Review schema
    const restaurantIdString = req.user.userId.toString();
    const reviews = await Review.find({ restaurantId: restaurantIdString }).sort({ createdAt: -1 });
    
    console.log(`✅ Authenticated fetch - Found ${reviews.length} reviews for restaurant: ${restaurantIdString}`);
    if (reviews.length > 0) {
      console.log('   Sample reviews:');
      reviews.slice(0, 3).forEach((r, idx) => {
        console.log(`   [${idx + 1}] id=${r._id}, rating=${r.rating}, orderId=${r.orderId}, restaurantId=${r.restaurantId}`);
      });
    } else {
      console.log('   ⚠️ No reviews found for this restaurant');
    }
    
    res.json(reviews);
  } catch (error) {
    console.error('❌ Error fetching restaurant reviews:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get reviews for a restaurant (unauthenticated - specific path)
router.get('/restaurant/:restaurantId', async (req, res) => {
  try {
    const { restaurantId } = req.params;
    console.log('\n📋 Fetching reviews for restaurant:', restaurantId);
    
    const reviews = await Review.find({ restaurantId }).sort({ createdAt: -1 });
    console.log(`✅ Found ${reviews.length} reviews for restaurant: ${restaurantId}`);
    res.json(reviews);
  } catch (error) {
    console.error('❌ Error fetching restaurant reviews:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create review
router.post('/', verifyJWT, async (req, res) => {
  try {
    const { orderId, rating, comment, imageUrl } = req.body;
    
    console.log('\n📝 REVIEW CREATE: Starting review creation');
    console.log('   orderId: ' + orderId);
    console.log('   customer userId: ' + req.user.userId);
    console.log('   rating: ' + rating);
    console.log('   comment: ' + (comment ? comment.substring(0, 50) + '...' : 'none'));
    
    // Fetch order to get restaurantId
    console.log('   🔍 Looking up order by ID: ' + orderId);
    const order = await Order.findById(orderId);
    
    if (!order) {
      console.log('   ❌ ORDER NOT FOUND! OrderId: ' + orderId);
      return res.status(404).json({ error: 'Order not found' });
    }
    
    console.log('   ✅ Order found!');
    console.log('      Order._id: ' + order._id);
    console.log('      Order.restaurantId: ' + order.restaurantId);
    console.log('      Order.customerId: ' + order.customerId);
    console.log('      Order.status: ' + order.status);
    
    const review = await Review.create({
      orderId,
      restaurantId: order.restaurantId,
      customerId: req.user.userId,
      customerName: req.user.email?.split('@')[0],
      rating,
      comment,
      imageUrl,
    });
    
    console.log('   ✅ REVIEW CREATED SUCCESSFULLY!');
    console.log('      Review._id: ' + review._id);
    console.log('      Review.restaurantId: ' + review.restaurantId);
    console.log('      Review.rating: ' + review.rating);
    
    res.status(201).json({ success: true, review });
  } catch (error) {
    console.error('❌ ERROR CREATING REVIEW:', error.message);
    console.error('   Full error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all reviews (generic route - MUST come after specific ones)
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
