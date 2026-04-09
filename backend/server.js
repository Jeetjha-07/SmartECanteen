require('dotenv').config();

// ✅ CRITICAL: Validate required environment variables before starting
const requiredEnvVars = ['MONGODB_URI', 'JWT_SECRET'];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  console.error('❌ FATAL ERROR: Missing required environment variables:');
  missingEnvVars.forEach(envVar => console.error(`   - ${envVar}`));
  console.error('\n🚨 Server cannot start without these variables!');
  console.error('📖 See RENDER_DEPLOYMENT.md for setup instructions.\n');
  process.exit(1);
}

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
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

// Graceful shutdown for Render
const gracefulShutdown = async (signal) => {
  console.log(`\n📍 ${signal} signal received: closing HTTP server`);
  
  server.close(async () => {
    console.log('✅ HTTP server closed');
    
    try {
      await mongoose.connection.close();
      console.log('✅ MongoDB connection closed');
    } catch (err) {
      console.error('❌ Error closing MongoDB connection:', err);
    }
    
    process.exit(0);
  });

  // Force shutdown after 30 seconds
  setTimeout(() => {
    console.error('❌ Forced shutdown - connections still active');
    process.exit(1);
  }, 30000);
};

// Handle termination signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
