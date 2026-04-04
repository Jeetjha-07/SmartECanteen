const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: { type: String, unique: true, required: true, lowercase: true },
    password: { type: String, required: true }, // For MongoDB native auth
    name: { type: String, required: true },
    role: {
      type: String,
      enum: ['customer', 'restaurant'],
      default: 'customer',
    },
    restaurantId: String,
    phoneNumber: String,
    address: String,
    profileImage: String,
    fcmToken: String,
    isActive: { type: Boolean, default: true },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

userSchema.index({ email: 1 });

module.exports = mongoose.model('User', userSchema);
