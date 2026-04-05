const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Verify JWT token
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

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role = 'customer' } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required' });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      password: hashedPassword,
      role,
      isActive: true,
      // For restaurant users, restaurantId is their own userId
      restaurantId: role === 'restaurant' ? null : undefined,
    });

    // For restaurant users, set restaurantId to their own _id
    if (role === 'restaurant') {
      user.restaurantId = user._id.toString();
      await user.save();
      console.log(`🍽️ Created restaurant user: ${user.email}, restaurantId: ${user.restaurantId}`);
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.role, restaurantId: user.restaurantId },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      success: true,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        restaurantId: user.restaurantId,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || !user.password) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email, 
        role: user.role,
        restaurantId: user.restaurantId // Include restaurantId in JWT for restaurants
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    if (user.role === 'restaurant') {
      console.log(`🍽️ Restaurant login: ${user.email}, restaurantId: ${user.restaurantId}`);
    }

    res.json({
      success: true,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        restaurantId: user.restaurantId,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get current user
router.get('/me', verifyJWT, async (req, res) => {
  try {
    console.log('\n👤 GET /users/me - Request');
    console.log('   req.user.userId: ' + req.user.userId);
    console.log('   req.user.role: ' + req.user.role);
    console.log('   req.user.restaurantId: ' + req.user.restaurantId);
    
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    console.log('   DB User found:');
    console.log('   user._id: ' + user._id);
    console.log('   user.role: ' + user.role);
    console.log('   user.restaurantId: ' + user.restaurantId);
    
    if (user.role === 'restaurant' && !user.restaurantId) {
      console.log('   ⚠️ WARNING: Restaurant user has no restaurantId!');
    }
    
    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      phoneNumber: user.phoneNumber,
      address: user.address,
      restaurantId: user.restaurantId,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update current user
router.put('/me', verifyJWT, async (req, res) => {
  try {
    const { name, phoneNumber, address, profileImage } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { name, phoneNumber, address, profileImage, updatedAt: new Date() },
      { new: true }
    );
    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Maintenance: Fix restaurant users missing restaurantId (admin only)
router.post('/maintenance/fix-restaurant-ids', async (req, res) => {
  try {
    // Find all restaurant users without restaurantId
    const broken = await User.find({ role: 'restaurant', restaurantId: { $in: [null, '', undefined] } });
    
    console.log(`🔧 Fixing ${broken.length} restaurant users missing restaurantId`);
    
    for (const user of broken) {
      user.restaurantId = user._id.toString();
      await user.save();
      console.log(`✅ Fixed: ${user.email} -> restaurantId: ${user.restaurantId}`);
    }
    
    res.json({
      success: true,
      message: `Fixed ${broken.length} restaurant users`,
      fixed: broken.length,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user by ID (for restaurant profile viewing)
router.get('/:userId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      phoneNumber: user.phoneNumber,
      address: user.address,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
