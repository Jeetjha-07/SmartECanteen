const express = require('express');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Restaurant = require('../models/Restaurant');
const MenuItem = require('../models/MenuItem');
const User = require('../models/User');
const { JWT_SECRET } = require('../config/jwt');
const { uploadToCloudinary, deleteFromCloudinary } = require('../utils/cloudinary');

const router = express.Router();

// Configure multer for file uploads
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    // Create unique filename with timestamp
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    console.log(`\n📸 ========== FILE UPLOAD VALIDATION ==========`);
    console.log(`Filename: ${file.originalname}`);
    console.log(`File size: ${file.size} bytes`);
    console.log(`MIME type received: "${file.mimetype}"`);
    console.log(`Extension: ${path.extname(file.originalname)}`);
    
    // Check file extension - more lenient
    const ext = path.extname(file.originalname).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    const extname = validExtensions.includes(ext);
    
    // Check MIME type - accept any image/* type
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

// Middleware to verify JWT token
const verifyJWT = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized: No token provided' });
    }
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

// Register/Create Restaurant
router.post('/register', verifyJWT, async (req, res) => {
  try {
    const {
      restaurantName,
      description,
      cuisineTypes,
      address,
      phone,
      city,
      zipCode,
      coordinates,
      deliveryTime,
      deliveryCharge,
      minOrderValue,
      operatingHours,
      defaultTimeSlotCapacity,
      bankDetails,
      isVerified,
      isOpen,
      imageUrl, // Now accept imageUrl from request body (from /upload endpoint)
    } = req.body;

    // Check if restaurant already exists for this user
    const existingRestaurant = await Restaurant.findOne({
      restaurantId: req.user.userId,
    });

    if (existingRestaurant) {
      return res.status(400).json({ error: 'Restaurant already registered for this account' });
    }

    // Use provided Cloudinary imageUrl or placeholder
    const finalImageUrl = imageUrl || 'https://res.cloudinary.com/deeifvoqv/image/upload/v1/smartcanteen/placeholder.png';
    console.log(`📸 Restaurant image URL: ${finalImageUrl}`);

    const restaurant = new Restaurant({
      restaurantId: req.user.userId,
      restaurantName,
      description,
      imageUrl: finalImageUrl, // Store Cloudinary URL
      cuisineTypes: cuisineTypes ? (typeof cuisineTypes === 'string' ? [cuisineTypes] : cuisineTypes) : ['Multi-Cuisine'],
      address,
      phone,
      city,
      zipCode,
      coordinates,
      deliveryTime: deliveryTime || 30,
      deliveryCharge: deliveryCharge || 0,
      minOrderValue: minOrderValue || 0,
      operatingHours,
      defaultTimeSlotCapacity: defaultTimeSlotCapacity || 20,
      bankDetails,
      shopRegistered: true, // Set to true when registering
      isVerified: isVerified !== undefined ? isVerified : true, // Default to true
      isOpen: isOpen !== undefined ? isOpen : true, // Default to true
    });

    await restaurant.save();

    // Update user role and set restaurantId to their own userId for consistency
    // This ensures: order.restaurantId = req.user.userId = user.restaurantId = restaurant.restaurantId
    // IMPORTANT: Convert to string to match Order schema (restaurantId: String)
    await User.findByIdAndUpdate(
      req.user.userId,
      {
        role: 'restaurant',
        restaurantId: req.user.userId.toString(),  // Convert to string!
      }
    );

    console.log('🍽️ Restaurant registered successfully:');
    console.log('   restaurantId:', req.user.userId + '');
    console.log('   Restaurant._id:', restaurant._id);
    console.log('   Restaurant.restaurantId:', req.user.userId + '');
    console.log('   User.restaurantId (updated to):', req.user.userId.toString());

    res.status(201).json({
      message: 'Restaurant registered successfully',
      restaurant,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Upload restaurant image to Cloudinary (without creating restaurant)
router.post('/upload', verifyJWT, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    console.log(`📤 Uploading restaurant image to Cloudinary...`);
    console.log(`   File: ${req.file.originalname} (${req.file.size} bytes)`);

    // Upload to Cloudinary
    const cloudinaryUrl = await uploadToCloudinary(
      req.file.buffer,
      'smartcanteen/restaurants',
      `restaurant_${req.user.userId}_${Date.now()}`
    );

    console.log(`✅ Restaurant image uploaded to Cloudinary: ${cloudinaryUrl}`);

    res.json({
      success: true,
      imageUrl: cloudinaryUrl,
      message: 'Image uploaded successfully to Cloudinary'
    });
  } catch (error) {
    console.error('❌ Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all restaurants (for customer browsing)
router.get('/all', async (req, res) => {
  try {
    const { city, cuisine, search, sortBy } = req.query;
    let query = { isVerified: true, isOpen: true };

    if (city) {
      query.city = city;
    }

    if (cuisine) {
      query.cuisineTypes = { $in: [cuisine] };
    }

    if (search) {
      query.$or = [
        { restaurantName: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    let restaurants = await Restaurant.find(query).lean();

    // Sort by rating or delivery time
    if (sortBy === 'rating') {
      restaurants.sort((a, b) => b.averageRating - a.averageRating);
    } else if (sortBy === 'deliveryTime') {
      restaurants.sort((a, b) => a.deliveryTime - b.deliveryTime);
    }

    res.json(restaurants);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get restaurant details by ID
router.get('/:restaurantId', async (req, res) => {
  try {
    const restaurant = await Restaurant.findOne({
      restaurantId: req.params.restaurantId,
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    res.json(restaurant);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get my restaurant (logged-in restaurant owner)
router.get('/owner/profile', verifyJWT, async (req, res) => {
  try {
    const restaurant = await Restaurant.findOne({
      restaurantId: req.user.userId,
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    res.json(restaurant);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update restaurant details
router.put('/owner/update', verifyJWT, upload.single('image'), async (req, res) => {
  try {
    const updates = req.body;

    // Handle image upload if provided
    if (req.file) {
      updates.imageUrl = `/uploads/${req.file.filename}`;
      console.log(`📸 Restaurant image updated: ${updates.imageUrl}`);
      
      // Delete old image if it exists and is not the placeholder
      const oldRestaurant = await Restaurant.findOne({ restaurantId: req.user.userId });
      if (oldRestaurant && oldRestaurant.imageUrl && !oldRestaurant.imageUrl.includes('placeholder')) {
        const oldImagePath = path.join(__dirname, '../' + oldRestaurant.imageUrl);
        fs.unlink(oldImagePath, (err) => {
          if (err) console.error('Error deleting old image:', err);
          else console.log('✅ Old image deleted');
        });
      }
    }

    const restaurant = await Restaurant.findOneAndUpdate(
      { restaurantId: req.user.userId },
      updates,
      { new: true }
    );

    if (!restaurant) {
      // Clean up uploaded file in case of error
      if (req.file) {
        fs.unlink(req.file.path, (err) => {
          if (err) console.error('Error deleting file:', err);
        });
      }
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    res.json({
      message: 'Restaurant updated successfully',
      restaurant,
    });
  } catch (error) {
    // Clean up uploaded file in case of error
    if (req.file) {
      fs.unlink(req.file.path, (err) => {
        if (err) console.error('Error deleting file:', err);
      });
    }
    res.status(500).json({ error: error.message });
  }
});

// Update time slot capacity
router.put('/owner/timeslot-capacity', verifyJWT, async (req, res) => {
  try {
    const { defaultTimeSlotCapacity, timeSlotDuration } = req.body;

    const restaurant = await Restaurant.findOneAndUpdate(
      { restaurantId: req.user.userId },
      {
        defaultTimeSlotCapacity: defaultTimeSlotCapacity || 20,
        timeSlotDuration: timeSlotDuration || 15,
      },
      { new: true }
    );

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    res.json({
      message: 'Time slot settings updated',
      restaurant,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Maintenance: Fix restaurantId mismatch for existing restaurants
router.post('/maintenance/fix-restaurant-ids', async (req, res) => {
  try {
    console.log('🔧 Starting restaurantId consistency check...');
    
    // Get all restaurant users
    const restaurantUsers = await User.find({ role: 'restaurant' });
    console.log(`Found ${restaurantUsers.length} restaurant users`);
    
    let fixed = 0;
    const results = [];
    
    for (const user of restaurantUsers) {
      // restaurantId should equal the user's own _id (req.user.userId)
      // NOT the restaurant's _id
      const correctRestaurantId = user._id.toString();
      
      if (user.restaurantId !== correctRestaurantId) {
        console.log(`⚠️ User ${user.email} has mismatched restaurantId:`);
        console.log(`   Current: ${user.restaurantId}, Should be: ${correctRestaurantId}`);
        
        // Update to correct value (user's own _id)
        const oldRestaurantId = user.restaurantId;
        user.restaurantId = correctRestaurantId;
        await user.save();
        
        results.push({
          email: user.email,
          userId: user._id.toString(),
          oldRestaurantId,
          newRestaurantId: correctRestaurantId,
          status: 'fixed'
        });
        fixed++;
        console.log(`✅ Fixed ${user.email}: restaurantId = ${correctRestaurantId}`);
      }
    }
    
    console.log(`✅ Fixed ${fixed} restaurantId mismatches`);
    res.json({
      success: true,
      message: `Fixed ${fixed} restaurantId mismatches. Reviews and analytics should now work correctly.`,
      fixed,
      details: results,
    });
  } catch (error) {
    console.error('❌ Error fixing restaurantIds:', error);
    res.status(500).json({ error: error.message });
  }
});

// Check if restaurant's shop is registered
router.get('/owner/registration-status', verifyJWT, async (req, res) => {
  try {
    const restaurant = await Restaurant.findOne({
      restaurantId: req.user.userId,
    });

    if (!restaurant) {
      return res.json({
        success: true,
        isRegistered: false,
        message: 'Shop registration not started',
      });
    }

    res.json({
      success: true,
      isRegistered: restaurant.shopRegistered === true,
      restaurant: restaurant,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
