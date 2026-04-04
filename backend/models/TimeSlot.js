const mongoose = require('mongoose');

const timeSlotSchema = new mongoose.Schema(
  {
    restaurantId: { type: String, required: true }, // Foreign key to Restaurant
    date: { type: Date, required: true }, // Date of the time slot
    startTime: { type: String, required: true }, // e.g., "10:00"
    endTime: { type: String, required: true }, // e.g., "10:15"
    capacity: { type: Number, required: true }, // Max orders allowed in this slot
    currentOrders: { type: Number, default: 0 }, // Current orders in this slot
    isAvailable: { type: Boolean, default: true }, // Whether slot is open for orders
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

// Compound index to ensure unique slot per restaurant per date/time
timeSlotSchema.index({ restaurantId: 1, date: 1, startTime: 1 }, { unique: true });

module.exports = mongoose.model('TimeSlot', timeSlotSchema);
