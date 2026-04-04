require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// MongoDB Connection
let mongoConnected = false;
mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => {
    mongoConnected = true;
    console.log('✅ MongoDB connected');
  })
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err);
    console.error('MONGODB_URI:', process.env.MONGODB_URI);
  });

// Middleware to check MongoDB connection
const checkMongoConnection = (req, res, next) => {
  if (!mongoConnected || mongoose.connection.readyState !== 1) {
    return res.status(503).json({ error: 'Database connection failed. Please try again.' });
  }
  next();
};

// Routes (with database check)
app.use('/api/users', checkMongoConnection, require('./routes/users'));
app.use('/api/menu', checkMongoConnection, require('./routes/menu'));
app.use('/api/orders', checkMongoConnection, require('./routes/orders'));
app.use('/api/reviews', checkMongoConnection, require('./routes/reviews'));
app.use('/api/restaurants', checkMongoConnection, require('./routes/restaurants'));
app.use('/api/coupons', checkMongoConnection, require('./routes/coupons'));
app.use('/api/timeslots', checkMongoConnection, require('./routes/timeslots'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'Server is running' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
