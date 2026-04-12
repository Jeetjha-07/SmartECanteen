const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    customerId: { type: String, required: true }, // Firebase Auth UID
    customerName: String,
    customerPhone: String,
    deliveryAddress: String,
    restaurantId: { type: String, required: true }, // Link to Restaurant
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
    subtotal: Number, // Before discount
    discountAmount: { type: Number, default: 0 },
    couponCode: String, // Coupon applied
    couponDiscount: { type: Number, default: 0 },
    paymentMethod: {
      type: String,
      enum: ['Card', 'UPI', 'NetBanking', 'Wallet', 'COD', 'Razorpay'],
      default: 'COD',
    },
    paymentStatus: {
      type: String,
      enum: ['Pending', 'Completed', 'Failed'],
      default: 'Pending',
    },
    // Razorpay payment details
    razorpay_order_id: String, // Razorpay order ID
    razorpay_payment_id: String, // Razorpay payment ID
    paymentVerifiedAt: Date, // When payment was verified
    status: {
      type: String,
      enum: ['Pending', 'Preparing', 'Ready', 'Delivered', 'Cancelled'],
      default: 'Pending',
    },
    specialInstructions: String,
    requestedTimeSlot: {
      date: Date,
      startTime: String,
      endTime: String,
    },
    estimatedDeliveryTime: Date,
    deliveredAt: Date,
    orderDate: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema);
