const express = require('express');
const admin = require('firebase-admin');
const User = require('../models/User');

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

// Create or update user (called after Firebase signup)
router.post('/sync', verifyToken, async (req, res) => {
  try {
    const { name, role = 'customer' } = req.body;
    const { uid, email } = req.user;

    let user = await User.findOne({ uid });

    if (!user) {
      // Create new user
      user = await User.create({
        uid,
        name: name || email.split('@')[0],
        email,
        role,
      });
    } else {
      // Update existing user
      user.name = name || user.name;
      user.role = role || user.role;
      await user.save();
    }

    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get current user
router.get('/me', verifyToken, async (req, res) => {
  try {
    const user = await User.findOne({ uid: req.user.uid });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update current user
router.put('/me', verifyToken, async (req, res) => {
  try {
    const { name, phoneNumber, address, profileImage } = req.body;
    const user = await User.findOneAndUpdate(
      { uid: req.user.uid },
      { name, phoneNumber, address, profileImage, updatedAt: new Date() },
      { new: true }
    );
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user by ID (for restaurant profile viewing)
router.get('/:userId', async (req, res) => {
  try {
    const user = await User.findOne({ uid: req.params.userId });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
