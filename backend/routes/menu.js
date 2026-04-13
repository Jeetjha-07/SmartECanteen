const express = require('express');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const cloudinary = require('cloudinary').v2;
const MenuItem = require('../models/MenuItem');
const Restaurant = require('../models/Restaurant');
const User = require('../models/User');
const { JWT_SECRET } = require('../config/jwt');

const router = express.Router();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

console.log('☁️  Cloudinary configured:', {
  cloudName: process.env.CLOUDINARY_CLOUD_NAME ? '✅' : '❌',
  apiKey: process.env.CLOUDINARY_API_KEY ? '✅' : '❌',
  apiSecret: process.env.CLOUDINARY_API_SECRET ? '✅' : '❌',
});

// Configure multer for memory storage (we'll upload to Cloudinary)
const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    console.log(`\n📸 ========== FILE UPLOAD VALIDATION ==========`);
    console.log(`Filename: ${file.originalname}`);
    console.log(`File size: ${file.size} bytes`);
    console.log(`MIME type received: "${file.mimetype}"`);
    console.log(`Extension: ${path.extname(file.originalname)}`);
    
    // Check file extension
    const ext = path.extname(file.originalname).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const extname = validExtensions.includes(ext);
    
    // Check MIME type
    const mimetype = file.mimetype && file.mimetype.startsWith('image/');
    
    console.log(`Extension valid: ${extname} (${ext})`);
    console.log(`MIME type valid: ${mimetype}`);
    console.log(`========================================\n`);
    
    if (extname && mimetype) {
      console.log(`✅ File validation passed!`);
      return cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

// Helper function to upload image to Cloudinary
async function uploadToCloudinary(fileBuffer, fileName) {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        resource_type: 'auto',
        public_id: `smartcanteen/menu/${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        folder: 'smartcanteen/menu',
        quality: 'auto',
        fetch_format: 'auto',
      },
      (error, result) => {
        if (error) {
          console.error('❌ Cloudinary upload error:', error);
          reject(error);
        } else {
          console.log('✅ Cloudinary upload successful:', result.secure_url);
          resolve(result.secure_url);
        }
      }
    );
    
    uploadStream.end(fileBuffer);
  });
}

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
router.post('/', verifyJWT, upload.single('image'), async (req, res) => {
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

    const { name, description, price, category, preparationTime } = req.body;
    
    // Validate required fields
    if (!name || !price || !category) {
      return res.status(400).json({ error: 'Missing required fields: name, price, category' });
    }
    
    // Handle image upload
    let imageUrl = req.body.imageUrl || ''; // Check if imageUrl is in request body (from /menu/upload endpoint)
    if (req.file) {
      // If file is uploaded directly to this endpoint, upload to Cloudinary
      console.log(`📤 Uploading ${req.file.originalname} to Cloudinary...`);
      imageUrl = await uploadToCloudinary(req.file.buffer, req.file.originalname);
      console.log(`☁️  Image URL: ${imageUrl}`);
    } else if (imageUrl) {
      // If imageUrl is in body (from /menu/upload), use it
      console.log(`📸 Using image URL from body: ${imageUrl}`);
    }
    
    console.log('📝 Creating menu item:', { name, price, category, restaurantId, imageUrl });
    
    const item = await MenuItem.create({
      name: name.trim(),
      description: description?.trim() || '',
      price: Number(price),
      imageUrl: imageUrl, // Store the Cloudinary URL
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
router.put('/:id', verifyJWT, upload.single('image'), async (req, res) => {
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

    const { name, description, price, category, isAvailable, preparationTime } = req.body;
    
    // Build update object
    let updateData = {
      name,
      description,
      price,
      category,
      isAvailable,
      preparationTime,
      updatedAt: new Date()
    };

    // Handle image upload if provided
    if (req.file) {
      console.log(`📤 Uploading new image to Cloudinary...`);
      updateData.imageUrl = await uploadToCloudinary(req.file.buffer, req.file.originalname);
      console.log(`☁️  Image updated: ${updateData.imageUrl}`);
    } else if (req.body.imageUrl && req.body.imageUrl !== existingItem.imageUrl) {
      // If imageUrl is in body (from /menu/upload), use it
      updateData.imageUrl = req.body.imageUrl;
      console.log(`📸 Menu item image updated (from body): ${updateData.imageUrl}`);
    }
    
    const item = await MenuItem.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    );
    
    res.json(item);
  } catch (error) {
    console.error('❌ Error updating menu item:', error);
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

    // Delete image file before deleting the database record
    if (item.imageUrl) {
      console.log(`🗑️  Deleting image for menu item: ${item.name}`);
      deleteImageFile(item.imageUrl);
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
    console.log('🔄 Toggle availability request for item:', req.params.id);
    console.log('📦 Request body:', req.body);

    const { isAvailable } = req.body;

    // Validate that isAvailable is provided and is a boolean
    if (isAvailable === undefined || isAvailable === null) {
      return res.status(400).json({ error: 'isAvailable field is required and must be a boolean value' });
    }

    if (typeof isAvailable !== 'boolean') {
      return res.status(400).json({ error: 'isAvailable must be a boolean (true or false)' });
    }

    const item = await MenuItem.findById(req.params.id);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    console.log('✅ Found item:', item.name);

    // Get restaurant ID from User profile
    const user = await User.findById(req.user.userId);
    if (!user || !user.restaurantId) {
      return res.status(400).json({ error: 'Restaurant not fully registered. Complete onboarding first.' });
    }

    const restaurantId = user.restaurantId;
    
    // Verify ownership
    if (item.restaurantId !== restaurantId) {
      console.log('❌ Ownership mismatch:', item.restaurantId, 'vs', restaurantId);
      return res.status(403).json({ error: 'You can only toggle your own items' });
    }

    // Verify restaurant exists (no need for full registration for toggling)
    const restaurant = await Restaurant.findById(restaurantId);
    if (!restaurant) {
      return res.status(400).json({ 
        error: 'Restaurant not found' 
      });
    }

    console.log('🔄 Updating item isAvailable to:', isAvailable);

    const updatedItem = await MenuItem.findByIdAndUpdate(
      req.params.id,
      { 
        isAvailable: isAvailable,
        updatedAt: new Date() 
      },
      { new: true, runValidators: true }
    );

    console.log('✅ Item updated successfully:', updatedItem.name, 'isAvailable:', updatedItem.isAvailable);

    res.json(updatedItem);
  } catch (error) {
    console.error('❌ Error toggling item availability:', error);
    res.status(500).json({ error: error.message });
  }
});

// Upload image for menu item (without creating item)
router.post('/upload', verifyJWT, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    // Get restaurant to verify shop is registered
    const user = req.user;
    const restaurant = await Restaurant.findOne({
      restaurantId: user.userId,
    });

    if (!restaurant) {
      return res.status(400).json({ 
        error: 'Restaurant not found. Please register your restaurant first.' 
      });
    }

    if (!restaurant.shopRegistered) {
      return res.status(400).json({ 
        error: 'Shop must be registered first before uploading menu item images.' 
      });
    }

    // Upload to Cloudinary
    console.log(`📤 Uploading ${req.file.originalname} to Cloudinary...`);
    const imageUrl = await uploadToCloudinary(req.file.buffer, req.file.originalname);
    console.log(`☁️  Image URL: ${imageUrl}`);

    res.json({
      success: true,
      imageUrl: imageUrl,
      message: 'Image uploaded successfully'
    });
  } catch (error) {
    console.error('❌ Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
