const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    description: String,
    price: { type: Number, required: true },
    imageUrl: String, // URL to image on Cloudinary
    category: { type: String, required: true },
    isAvailable: { type: Boolean, default: true },
    preparationTime: Number, // in minutes
    rating: { type: Number, default: 0, min: 0, max: 5 },
    ratingCount: { type: Number, default: 0 },
    restaurantId: String, // If multi-restaurant support
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('MenuItem', menuItemSchema);
