const express = require('express');
const admin = require('firebase-admin');
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

// Get all available menu items (for customers)
router.get('/', async (req, res) => {
  try {
    const category = req.query.category;
    const query = { isAvailable: true };
    
    if (category) {
      query.category = category;
    }

    const items = await MenuItem.find(query).sort({ category: 1 });
    res.json(items);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get ALL menu items including unavailable (for restaurant admin)
router.get('/all/items', verifyToken, async (req, res) => {
  try {
    const category = req.query.category;
    const query = {}; // No filter - get ALL items
    
    if (category) {
      query.category = category;
    }

    console.log(`📋 Fetching ALL menu items (including unavailable) for restaurant: ${req.user.uid}`);
    const items = await MenuItem.find(query).sort({ category: 1 });
    console.log(`✅ Found ${items.length} items (available + unavailable)`);
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
router.post('/', verifyToken, async (req, res) => {
  try {
    const { name, description, price, imageUrl, category, preparationTime } = req.body;
    
    // Validate required fields
    if (!name || !price || !category) {
      return res.status(400).json({ error: 'Missing required fields: name, price, category' });
    }
    
    console.log('📝 Creating menu item:', { name, price, category, uid: req.user.uid });
    
    const item = await MenuItem.create({
      name: name.trim(),
      description: description?.trim() || '',
      price: Number(price),
      imageUrl: imageUrl?.trim() || '',
      category: category.trim(),
      preparationTime: preparationTime || 30,
      restaurantId: req.user.uid,
    });
    
    console.log('✅ Menu item created in MongoDB:', item._id);
    res.status(201).json({ success: true, item });
  } catch (error) {
    console.error('❌ Error creating menu item:', error);
    res.status(500).json({ error: error.message, details: error.stack });
  }
});

// Update menu item
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const { name, description, price, imageUrl, category, isAvailable, preparationTime } = req.body;
    
    const item = await MenuItem.findByIdAndUpdate(
      req.params.id,
      { name, description, price, imageUrl, category, isAvailable, preparationTime, updatedAt: new Date() },
      { new: true }
    );
    
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }
    
    res.json(item);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete menu item
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const item = await MenuItem.findByIdAndDelete(req.params.id);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }
    res.json({ success: true, message: 'Item deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Toggle availability
router.patch('/:id/availability', verifyToken, async (req, res) => {
  try {
    const { isAvailable } = req.body;
    const item = await MenuItem.findByIdAndUpdate(
      req.params.id,
      { isAvailable, updatedAt: new Date() },
      { new: true }
    );
    res.json(item);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
