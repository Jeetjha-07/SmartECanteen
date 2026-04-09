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
    });

    await coupon.save();

    res.status(201).json({
      message: 'Coupon created successfully',
      coupon,
    });
  } catch (error) {
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

    const coupon = await Coupon.findOne({
      code: code.toUpperCase(),
      restaurantId,
      isActive: true,
    });

    if (!coupon) {
      return res.status(404).json({ error: 'Coupon not found or inactive' });
    }

    const now = new Date();
    if (now < coupon.validFrom || now > coupon.validUntil) {
      return res.status(400).json({ error: 'Coupon has expired or not yet valid' });
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

    const updates = req.body;
    Object.assign(coupon, updates);
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
