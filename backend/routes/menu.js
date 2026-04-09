const express = require('express');
const jwt = require('jsonwebtoken');
const MenuItem = require('../models/MenuItem');
const Restaurant = require('../models/Restaurant');
const User = require('../models/User');
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

// Get all available menu items (for customers)
router.get('/', async (req, res) => {
  try {
    const category = req.query.category;
    const restaurantId = req.query.restaurantId;
    const query = { isAvailable: true };
    
    console.log('📋 Menu API called with:', { category, restaurantId });
    
    if (category) {
      query.category = category;
    }

    if (restaurantId) {
      query.restaurantId = restaurantId;
    }

    const items = await MenuItem.find(query).sort({ category: 1 });
    console.log(`✅ Found ${items.length} menu items matching query:`, { category, restaurantId });
    res.json(items);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get ALL menu items including unavailable (for restaurant admin)
router.get('/all/items', verifyJWT, async (req, res) => {
  try {
    // Only restaurants can see their all items
    if (req.user.role !== 'restaurant') {
      return res.status(403).json({ error: 'Only restaurants can access this endpoint' });
    }

    // Get restaurant by userId to verify it exists
    const restaurant = await Restaurant.findOne({ restaurantId: req.user.userId });
    if (!restaurant) {
      console.log('⚠️ Restaurant not found for userId:', req.user.userId);
      return res.json([]);
    }

    // Use userId as restaurantId (matching how items are created)
    const restaurantId = req.user.userId;
    const category = req.query.category;
    const query = { restaurantId: restaurantId }; // Filter by userId
    
    if (category) {
      query.category = category;
    }

    console.log(`📋 Fetching ALL menu items for restaurant userId: ${restaurantId}`);
    const items = await MenuItem.find(query).sort({ category: 1 });
    console.log(`✅ Found ${items.length} items for this restaurant`);
    res.json(items);
  } catch (error) {
    console.error('❌ Error fetching all menu items:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get menu item by ID
router.get('/:id', async (req, res) => {
  try {
    const item = await MenuItem.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }
    res.json(item);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create menu item (Restaurant only)
router.post('/', verifyJWT, async (req, res) => {
  try {
    // Verify it's a restaurant
    if (req.user.role !== 'restaurant') {
      return res.status(403).json({ error: 'Only restaurants can create menu items' });
    }

    // Get restaurant by userId (restaurantId field in Restaurant document)
    const restaurant = await Restaurant.findOne({ restaurantId: req.user.userId });
    if (!restaurant) {
      return res.status(400).json({ error: 'Restaurant not found. Please register your restaurant first.' });
    }

    if (!restaurant.shopRegistered) {
      return res.status(400).json({ 
        error: 'Shop must be registered first before adding menu items. Please complete shop registration.' 
      });
    }

    // Use the userId as restaurantId for menu items (matching Restaurant.restaurantId field)
    const restaurantId = req.user.userId;

    const { name, description, price, imageUrl, category, preparationTime } = req.body;
    
    // Validate required fields
    if (!name || !price || !category) {
      return res.status(400).json({ error: 'Missing required fields: name, price, category' });
    }
    
    console.log('📝 Creating menu item:', { name, price, category, restaurantId });
    
    const item = await MenuItem.create({
      name: name.trim(),
      description: description?.trim() || '',
      price: Number(price),
      imageUrl: imageUrl?.trim() || '',
      category: category.trim(),
      preparationTime: preparationTime || 30,
      restaurantId: restaurantId, // Use restaurantId from User profile
    });
    
    console.log('✅ Menu item created in MongoDB:', item._id);
    res.status(201).json({ success: true, item });
  } catch (error) {
    console.error('❌ Error creating menu item:', error);
    res.status(500).json({ error: error.message, details: error.stack });
  }
});

// Update menu item
router.put('/:id', verifyJWT, async (req, res) => {
  try {
    // Verify ownership
    const existingItem = await MenuItem.findById(req.params.id);
    if (!existingItem) {
      return res.status(404).json({ error: 'Item not found' });
    }

    // Get restaurant by userId to verify ownership
    const restaurant = await Restaurant.findOne({ restaurantId: req.user.userId });
    if (!restaurant) {
      return res.status(400).json({ error: 'Restaurant not found. Please register your restaurant first.' });
    }

    const restaurantId = req.user.userId;
    
    if (existingItem.restaurantId !== restaurantId) {
      return res.status(403).json({ error: 'You can only update your own items' });
    }

    if (!restaurant.shopRegistered) {
      return res.status(400).json({ 
        error: 'Shop must be registered first before modifying menu items. Please complete shop registration.' 
      });
    }

    const { name, description, price, imageUrl, category, isAvailable, preparationTime } = req.body;
    
    const item = await MenuItem.findByIdAndUpdate(
      req.params.id,
      { name, description, price, imageUrl, category, isAvailable, preparationTime, updatedAt: new Date() },
      { new: true }
    );
    
    res.json(item);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete menu item
router.delete('/:id', verifyJWT, async (req, res) => {
  try {
    const item = await MenuItem.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    // Get restaurant by userId to verify ownership
    const restaurant = await Restaurant.findOne({ restaurantId: req.user.userId });
    if (!restaurant) {
      return res.status(400).json({ error: 'Restaurant not found. Please register your restaurant first.' });
    }

    const restaurantId = req.user.userId;
    
    // Verify ownership
    if (item.restaurantId !== restaurantId) {
      return res.status(403).json({ error: 'You can only delete your own items' });
    }

    if (!restaurant.shopRegistered) {
      return res.status(400).json({ 
        error: 'Shop must be registered first before modifying menu items. Please complete shop registration.' 
      });
    }

    await MenuItem.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Item deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Toggle availability
router.patch('/:id/availability', verifyJWT, async (req, res) => {
  try {
    const item = await MenuItem.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    // Get restaurant ID from User profile
    const user = await User.findById(req.user.userId);
    if (!user || !user.restaurantId) {
      return res.status(400).json({ error: 'Restaurant not fully registered. Complete onboarding first.' });
    }

    const restaurantId = user.restaurantId;
    
    // Verify ownership
    if (item.restaurantId !== restaurantId) {
      return res.status(403).json({ error: 'You can only toggle your own items' });
    }

    // Check if shop is registered
    const restaurant = await Restaurant.findById(restaurantId);
    if (!restaurant || !restaurant.shopRegistered) {
      return res.status(400).json({ 
        error: 'Shop must be registered first before modifying menu items. Please complete shop registration.' 
      });
    }

    const { isAvailable } = req.body;
    const updatedItem = await MenuItem.findByIdAndUpdate(
      req.params.id,
      { isAvailable, updatedAt: new Date() },
      { new: true }
    );
    res.json(updatedItem);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
