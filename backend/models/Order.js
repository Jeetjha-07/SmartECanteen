const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    customerId: { type: String, required: true }, // Firebase Auth UID
    customerName: String,
    customerPhone: String,
    deliveryAddress: String,
    items: [
      {
        foodItemId: mongoose.Schema.Types.ObjectId,
        foodItemName: String,
        price: Number,
        quantity: Number,
        imageUrl: String,
      },
    ],
    totalAmount: { type: Number, required: true },
    paymentMethod: {
      type: String,
      enum: ['Card', 'UPI', 'NetBanking', 'Wallet', 'COD'],
      default: 'Card',
    },
    paymentStatus: {
      type: String,
      enum: ['Pending', 'Completed', 'Failed'],
      default: 'Pending',
    },
    status: {
      type: String,
      enum: ['Pending', 'Preparing', 'Ready', 'Delivered', 'Cancelled'],
      default: 'Pending',
    },
    specialInstructions: String,
    estimatedDeliveryTime: Date,
    deliveredAt: Date,
    orderDate: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema);
