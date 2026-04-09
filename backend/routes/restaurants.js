const express = require('express');
const jwt = require('jsonwebtoken');
const Restaurant = require('../models/Restaurant');
const MenuItem = require('../models/MenuItem');
const User = require('../models/User');
const { JWT_SECRET } = require('../config/jwt');

const router = express.Router();

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
      imageUrl,
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
    } = req.body;

    // Check if restaurant already exists for this user
    const existingRestaurant = await Restaurant.findOne({
      restaurantId: req.user.userId,
    });

    if (existingRestaurant) {
      return res.status(400).json({ error: 'Restaurant already registered for this account' });
    }

    const restaurant = new Restaurant({
      restaurantId: req.user.userId,
      restaurantName,
      description,
      imageUrl,
      cuisineTypes,
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
router.put('/owner/update', verifyJWT, async (req, res) => {
  try {
    const updates = req.body;
    const restaurant = await Restaurant.findOneAndUpdate(
      { restaurantId: req.user.userId },
      updates,
      { new: true }
    );

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    res.json({
      message: 'Restaurant updated successfully',
      restaurant,
    });
  } catch (error) {
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

module.exports = router;
