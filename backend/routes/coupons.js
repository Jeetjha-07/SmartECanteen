const express = require('express');
const jwt = require('jsonwebtoken');
const Coupon = require('../models/Coupon');
const Restaurant = require('../models/Restaurant');
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

// Create coupon (restaurant owner only)
router.post('/create', verifyJWT, async (req, res) => {
  try {
    const {
      code,
      description,
      discountType,
      discountValue,
      minOrderValue,
      maxDiscount,
      maxUses,
      usesPerUser,
      validFrom,
      validUntil,
    } = req.body;

    // Get restaurant ID for this owner
    const restaurant = await Restaurant.findOne({
      restaurantId: req.user.userId,
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // Check if coupon code already exists
    const existingCoupon = await Coupon.findOne({
      code: code.toUpperCase(),
    });

    if (existingCoupon) {
      return res.status(400).json({ error: 'Coupon code already exists' });
    }

    const coupon = new Coupon({
      code: code.toUpperCase(),
      restaurantId: req.user.userId,
      description,
      discountType,
      discountValue,
      minOrderValue: minOrderValue || 0,
      maxDiscount,
      maxUses,
      usesPerUser: usesPerUser || 1,
      validFrom: new Date(validFrom),
      validUntil: new Date(validUntil),
      isActive: true, // Explicitly set to true when creating
      usedCount: 0, // Initialize to 0
    });

    console.log('✅ Creating coupon:', { code: coupon.code, restaurantId: coupon.restaurantId, isActive: coupon.isActive });
    await coupon.save();

    res.status(201).json({
      message: 'Coupon created successfully',
      coupon,
    });
  } catch (error) {
    console.error('❌ Coupon creation error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all coupons for a restaurant
router.get('/restaurant/:restaurantId', async (req, res) => {
  try {
    const coupons = await Coupon.find({
      restaurantId: req.params.restaurantId,
    });

    res.json(coupons);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get my coupons (logged-in restaurant)
router.get('/owner/my-coupons', verifyJWT, async (req, res) => {
  try {
    const coupons = await Coupon.find({
      restaurantId: req.user.userId,
    }).sort({ createdAt: -1 });

    res.json(coupons);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Validate and apply coupon
router.post('/validate', async (req, res) => {
  try {
    const { code, restaurantId, orderAmount } = req.body;

    // Debug logging
    console.log('🔍 Validating coupon:', { code, restaurantId, orderAmount });

    if (!code || !restaurantId) {
      return res.status(400).json({
        error: 'Missing required fields: code and restaurantId',
      });
    }

    const coupon = await Coupon.findOne({
      code: code.toUpperCase(),
      restaurantId: restaurantId,
    });

    console.log('📋 Coupon found:', coupon);

    if (!coupon) {
      return res.status(404).json({
        error: 'Coupon not found for this restaurant. Code or Restaurant ID may be incorrect.',
      });
    }

    // Check if coupon is active
    if (!coupon.isActive) {
      return res.status(400).json({
        error: 'This coupon has been deactivated by the restaurant',
      });
    }

    const now = new Date();
    if (now < coupon.validFrom || now > coupon.validUntil) {
      return res.status(400).json({
        error: 'Coupon has expired or is not yet valid',
      });
    }

    if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
      return res.status(400).json({ error: 'Coupon usage limit reached' });
    }

    if (orderAmount < coupon.minOrderValue) {
      return res.status(400).json({
        error: `Minimum order value of ₹${coupon.minOrderValue} required`,
      });
    }

    let discount = 0;
    if (coupon.discountType === 'percentage') {
      discount = (orderAmount * coupon.discountValue) / 100;
      if (coupon.maxDiscount && discount > coupon.maxDiscount) {
        discount = coupon.maxDiscount;
      }
    } else {
      discount = coupon.discountValue;
    }

    res.json({
      message: 'Coupon valid',
      coupon,
      discount,
      finalAmount: orderAmount - discount,
    });
  } catch (error) {
    console.error('❌ Coupon validation error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update coupon
router.put('/:couponId', verifyJWT, async (req, res) => {
  try {
    const coupon = await Coupon.findById(req.params.couponId);

    if (!coupon) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    if (coupon.restaurantId !== req.user.userId) {
      return res.status(403).json({ error: 'Unauthorized to update this coupon' });
    }

    // Only allow specific fields to be updated (prevent restaurantId tampering)
    const allowedFields = [
      'description',
      'discountType',
      'discountValue',
      'minOrderValue',
      'maxDiscount',
      'maxUses',
      'usesPerUser',
      'validFrom',
      'validUntil',
      'isActive',
    ];

    const updates = {};
    allowedFields.forEach((field) => {
      if (req.body.hasOwnProperty(field)) {
        updates[field] = req.body[field];
      }
    });

    // Ensure restaurantId is never changed
    updates.restaurantId = coupon.restaurantId;

    Object.assign(coupon, updates);
    coupon.updatedAt = new Date();
    await coupon.save();

    res.json({
      message: 'Coupon updated successfully',
      coupon,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete coupon
router.delete('/:couponId', verifyJWT, async (req, res) => {
  try {
    const coupon = await Coupon.findById(req.params.couponId);

    if (!coupon) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    if (coupon.restaurantId !== req.user.userId) {
      return res.status(403).json({ error: 'Unauthorized to delete this coupon' });
    }

    await Coupon.findByIdAndDelete(req.params.couponId);

    res.json({
      message: 'Coupon deleted successfully',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
