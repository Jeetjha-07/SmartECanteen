const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    uid: { type: String, unique: true, required: true }, // Firebase Auth UID
    name: { type: String, required: true },
    email: { type: String, unique: true, required: true },
    role: {
      type: String,
      enum: ['customer', 'restaurant'],
      default: 'customer',
    },
    phoneNumber: String,
    address: String,
    profileImage: String, // URL to image
    fcmToken: String, // For push notifications
    isActive: { type: Boolean, default: true },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
