const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema(
  {
    code: { type: String, unique: true, required: true, uppercase: true },
    restaurantId: { type: String, required: true }, // Foreign key to Restaurant
    description: String,
    discountType: {
      type: String,
      enum: ['percentage', 'fixed'],
      default: 'percentage',
    },
    discountValue: { type: Number, required: true }, // % or fixed amount
    minOrderValue: { type: Number, default: 0 }, // Minimum order value to use coupon
    maxDiscount: Number, // Maximum discount amount (for percentage)
    maxUses: Number, // Total uses allowed globally
    usesPerUser: { type: Number, default: 1 }, // Max times one user can use this coupon
    validFrom: { type: Date, required: true },
    validUntil: { type: Date, required: true },
    isActive: { type: Boolean, default: true },
    usedCount: { type: Number, default: 0 }, // Track global usage
    usedBy: [
      {
        userId: String,
        usedAt: Date,
        orderId: mongoose.Schema.Types.ObjectId,
      },
    ],
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Coupon', couponSchema);
