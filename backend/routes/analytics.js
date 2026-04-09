const express = require('express');
const jwt = require('jsonwebtoken');
const MLAnalytics = require('../services/mlAnalytics');
const { JWT_SECRET } = require('../config/jwt');

const router = express.Router();

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
    return res.status(401).json({ error: 'Invalid token' });
  }
};

/**
 * GET /api/analytics/predictions/sales
 * Get sales predictions for next 7 days
 */
router.get('/predictions/sales', verifyJWT, async (req, res) => {
  try {
    const { restaurantId } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`📊 Sales prediction request for restaurant: ${restaurantId}`);

    const prediction = await MLAnalytics.predictNextWeekSales(restaurantId);
    
    res.json({
      success: true,
      data: prediction,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching sales predictions:', error);
    res.status(500).json({ error: 'Failed to fetch sales predictions' });
  }
});

/**
 * GET /api/analytics/predictions/revenue
 * Get revenue predictions for next 7 days
 */
router.get('/predictions/revenue', verifyJWT, async (req, res) => {
  try {
    const { restaurantId } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`💰 Revenue prediction request for restaurant: ${restaurantId}`);

    const prediction = await MLAnalytics.predictNextWeekRevenue(restaurantId);
    
    res.json({
      success: true,
      data: prediction,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching revenue predictions:', error);
    res.status(500).json({ error: 'Failed to fetch revenue predictions' });
  }
});

/**
 * GET /api/analytics/top-items
 * Get top-selling items
 */
router.get('/top-items', verifyJWT, async (req, res) => {
  try {
    const { restaurantId, days = 30, limit = 10 } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`⭐ Top items request for restaurant: ${restaurantId}, days: ${days}`);

    const items = await MLAnalytics.getTopSellingItems(restaurantId, parseInt(days), parseInt(limit));
    
    res.json({
      success: true,
      data: items,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching top items:', error);
    res.status(500).json({ error: 'Failed to fetch top items' });
  }
});

/**
 * GET /api/analytics/low-items
 * Get low-performing items
 */
router.get('/low-items', verifyJWT, async (req, res) => {
  try {
    const { restaurantId, days = 30, limit = 5 } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`📉 Low items request for restaurant: ${restaurantId}`);

    const items = await MLAnalytics.getLowPerformingItems(restaurantId, parseInt(days), parseInt(limit));
    
    res.json({
      success: true,
      data: items,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching low items:', error);
    res.status(500).json({ error: 'Failed to fetch low items' });
  }
});

/**
 * GET /api/analytics/recommendations
 * Get AI-powered recommendations to boost sales
 */
router.get('/recommendations', verifyJWT, async (req, res) => {
  try {
    const { restaurantId } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`💡 Recommendations request for restaurant: ${restaurantId}`);

    const recommendations = await MLAnalytics.getSalesBoostRecommendations(restaurantId);
    
    res.json({
      success: true,
      data: recommendations,
      count: recommendations.length,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching recommendations:', error);
    res.status(500).json({ error: 'Failed to fetch recommendations' });
  }
});

/**
 * GET /api/analytics/sales-trend
 * Get historical sales trend
 */
router.get('/sales-trend', verifyJWT, async (req, res) => {
  try {
    const { restaurantId, days = 30 } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`📈 Sales trend request for restaurant: ${restaurantId}`);

    const trend = await MLAnalytics.getSalesTrend(restaurantId, parseInt(days));
    
    res.json({
      success: true,
      data: trend,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching sales trend:', error);
    res.status(500).json({ error: 'Failed to fetch sales trend' });
  }
});

/**
 * GET /api/analytics/revenue-trend
 * Get historical revenue trend
 */
router.get('/revenue-trend', verifyJWT, async (req, res) => {
  try {
    const { restaurantId, days = 30 } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`💵 Revenue trend request for restaurant: ${restaurantId}`);

    const trend = await MLAnalytics.getRevenueTrend(restaurantId, parseInt(days));
    
    res.json({
      success: true,
      data: trend,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching revenue trend:', error);
    res.status(500).json({ error: 'Failed to fetch revenue trend' });
  }
});

/**
 * GET /api/analytics/dashboard
 * Get comprehensive analytics dashboard
 */
router.get('/dashboard', verifyJWT, async (req, res) => {
  try {
    const { restaurantId } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'restaurantId is required' });
    }

    console.log(`🎯 Dashboard request for restaurant: ${restaurantId}`);

    const analytics = await MLAnalytics.getComprehensiveAnalytics(restaurantId);
    
    res.json({
      success: true,
      data: analytics,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error fetching analytics dashboard:', error);
    res.status(500).json({ error: 'Failed to fetch analytics dashboard' });
  }
});

module.exports = router;
