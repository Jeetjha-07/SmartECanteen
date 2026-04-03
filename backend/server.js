require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Firebase Admin SDK initialization
admin.initializeApp({
  projectId: process.env.FIREBASE_PROJECT_ID,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
});

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

// Firebase-Auth Middleware (Verify ID token from Flutter client)
const verifyFirebaseToken = async (req, res, next) => {
  const idToken = req.headers.authorization?.split('Bearer ')[1];

  if (!idToken) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Routes (with database check)
app.use('/api/users', checkMongoConnection, require('./routes/users'));
app.use('/api/menu', checkMongoConnection, require('./routes/menu'));
app.use('/api/orders', checkMongoConnection, require('./routes/orders'));
app.use('/api/reviews', checkMongoConnection, require('./routes/reviews'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'Server is running' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
