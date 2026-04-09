const express = require('express');
const jwt = require('jsonwebtoken');
const TimeSlot = require('../models/TimeSlot');
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

// Generate time slots for a day (automated - call once per day at midnight)
router.post('/generate', verifyJWT, async (req, res) => {
  try {
    const { date, startTime, endTime, capacity } = req.body; // Date format: "2025-04-03"
    // startTime and endTime format: "11:00", "23:00" (optional - use operating hours if not provided)

    const restaurant = await Restaurant.findOne({
      restaurantId: req.user.userId,
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // Determine operating times
    let openTime, closeTime;

    if (startTime && endTime) {
      // Use provided times
      const dateObj = new Date(date);
      const [openHour, openMin] = startTime.split(':').map(Number);
      const [closeHour, closeMin] = endTime.split(':').map(Number);

      openTime = new Date(dateObj);
      openTime.setHours(openHour, openMin, 0);

      closeTime = new Date(dateObj);
      closeTime.setHours(closeHour, closeMin, 0);
    } else {
      // Use operating hours from database
      const dateObj = new Date(date);
      const dayName = dateObj.toLocaleDateString('en-US', { weekday: 'lowercase' });
      const dayHours = restaurant.operatingHours[dayName];

      if (!dayHours || !dayHours.open || !dayHours.close) {
        return res.status(400).json({
          error: `No operating hours configured for ${dayName}. Please provide startTime and endTime.`,
        });
      }

      const [openHour, openMin] = dayHours.open.split(':').map(Number);
      const [closeHour, closeMin] = dayHours.close.split(':').map(Number);

      openTime = new Date(dateObj);
      openTime.setHours(openHour, openMin, 0);

      closeTime = new Date(dateObj);
      closeTime.setHours(closeHour, closeMin, 0);
    }

    // Determine capacity
    const slotCapacity = capacity || restaurant.defaultTimeSlotCapacity;

    // Delete all existing time slots for this date
    const dateObj = new Date(date);
    const deletedCount = await TimeSlot.deleteMany({
      restaurantId: req.user.userId,
      date: new Date(dateObj.toDateString()),
    });

    console.log(`🗑️ Deleted ${deletedCount.deletedCount} old time slots for ${date}`);

    // Create time slots
    const slots = [];
    const duration = restaurant.timeSlotDuration || 15;
    let currentTime = new Date(openTime);

    while (currentTime < closeTime) {
      const nextTime = new Date(currentTime.getTime() + duration * 60000);

      const startTimeStr = currentTime.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
      });
      const endTimeStr = nextTime.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
      });

      const slot = new TimeSlot({
        restaurantId: req.user.userId,
        date: new Date(dateObj.toDateString()),
        startTime: startTimeStr,
        endTime: endTimeStr,
        capacity: slotCapacity,
        currentOrders: 0,
        isAvailable: true,
      });

      await slot.save();
      slots.push(slot);

      currentTime = nextTime;
    }

    console.log(`✅ Generated ${slots.length} new time slots for ${date}`);
    res.json({
      message: `${deletedCount.deletedCount} old slots deleted. ${slots.length} new time slots generated for ${date}`,
      slots,
    });
  } catch (error) {
    console.error('❌ Error generating time slots:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get available time slots for a restaurant on a specific date
router.get('/available/:restaurantId/:date', async (req, res) => {
  try {
    const { restaurantId, date } = req.params;

    const dateObj = new Date(date);
    const slots = await TimeSlot.find({
      restaurantId,
      date: new Date(dateObj.toDateString()),
      isAvailable: true,
    }).sort({ startTime: 1 });

    res.json(slots);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all time slots for a restaurant (dashboard)
router.get('/owner/slots', verifyJWT, async (req, res) => {
  try {
    const { date } = req.query; // Optional: filter by date

    let query = { restaurantId: req.user.userId };

    if (date) {
      const dateObj = new Date(date);
      query.date = new Date(dateObj.toDateString());
    }

    const slots = await TimeSlot.find(query).sort({ date: 1, startTime: 1 });

    res.json(slots);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update time slot capacity
router.put('/:slotId', verifyJWT, async (req, res) => {
  try {
    const { capacity, isAvailable } = req.body;

    const slot = await TimeSlot.findById(req.params.slotId);

    if (!slot) {
      return res.status(404).json({ error: 'Time slot not found' });
    }

    if (slot.restaurantId !== req.user.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    if (req.body.capacity !== undefined) {
      if (req.body.capacity < slot.currentOrders) {
        return res.status(400).json({
          error: `Capacity cannot be less than current orders (${slot.currentOrders})`,
        });
      }
      slot.capacity = capacity;
    }

    if (isAvailable !== undefined) {
      slot.isAvailable = isAvailable;
    }

    await slot.save();

    res.json({
      message: 'Time slot updated',
      slot,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get slot statistics for the day
router.get('/owner/stats/:date', verifyJWT, async (req, res) => {
  try {
    const { date } = req.params;

    const dateObj = new Date(date);
    const slots = await TimeSlot.find({
      restaurantId: req.user.userId,
      date: new Date(dateObj.toDateString()),
    });

    const stats = {
      totalSlots: slots.length,
      totalCapacity: slots.reduce((sum, s) => sum + s.capacity, 0),
      totalOrders: slots.reduce((sum, s) => sum + s.currentOrders, 0),
      availableSlots: slots.filter((s) => s.isAvailable).length,
      slots,
    };

    res.json(stats);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
