const mongoose = require('mongoose');

const restaurantSchema = new mongoose.Schema(
  {
    restaurantId: { type: String, unique: true, required: true }, // Firebase Auth UID of restaurant owner
    restaurantName: { type: String, required: true },
    description: String,
    imageUrl: String, // Restaurant/shop image (Cloudinary URL)
    cuisineTypes: [String], // ['Italian', 'Chinese', 'Indian', etc.]
    address: String,
    phone: String,
    city: String,
    zipCode: String,
    coordinates: {
      latitude: Number,
      longitude: Number,
    },
    averageRating: { type: Number, default: 0, min: 0, max: 5 },
    totalRatings: { type: Number, default: 0 },
    isOpen: { type: Boolean, default: true },
    deliveryTime: Number, // in minutes
    deliveryCharge: { type: Number, default: 0 },
    minOrderValue: { type: Number, default: 0 },
    operatingHours: {
      monday: { open: String, close: String }, // e.g., "09:00", "21:00"
      tuesday: { open: String, close: String },
      wednesday: { open: String, close: String },
      thursday: { open: String, close: String },
      friday: { open: String, close: String },
      saturday: { open: String, close: String },
      sunday: { open: String, close: String },
    },
    defaultTimeSlotCapacity: { type: Number, default: 20 }, // orders per 15 min slot
    timeSlotDuration: { type: Number, default: 15 }, // in minutes
    bankDetails: {
      accountHolder: String,
      accountNumber: String,
      ifscCode: String,
      bankName: String,
    },
    shopRegistered: { type: Boolean, default: false }, // Must register shop before adding menu items
    isVerified: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Restaurant', restaurantSchema);
