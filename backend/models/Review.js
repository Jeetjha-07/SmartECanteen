const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    orderId: { type: mongoose.Schema.Types.ObjectId, required: true },
    customerId: { type: String, required: true }, // Firebase Auth UID
    customerName: String,
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: String,
    imageUrl: String, // Optional review image
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Review', reviewSchema);
