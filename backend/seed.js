require('dotenv').config();
const mongoose = require('mongoose');
const Restaurant = require('./models/Restaurant');

async function seedDatabase() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Clear existing sample restaurants
    await Restaurant.deleteMany({ restaurantId: { $regex: '^sample-' } });
    console.log('🧹 Cleared sample restaurants');

    console.log('\n✨ Database is ready! Restaurants will appear once they register and complete onboarding.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

seedDatabase();
