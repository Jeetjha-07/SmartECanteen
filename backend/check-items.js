require('dotenv').config();
const mongoose = require('mongoose');
const MenuItem = require('./models/MenuItem');
const Restaurant = require('./models/Restaurant');
const User = require('./models/User');

async function checkItems() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all restaurants
    const restaurants = await Restaurant.find({});
    console.log(`\n📋 Found ${restaurants.length} restaurants:`);
    restaurants.forEach(r => {
      console.log(`  - ${r.restaurantName} (id: ${r._id}, restaurantId: ${r.restaurantId})`);
    });

    // Get all menu items
    const items = await MenuItem.find({});
    console.log(`\n🍕 Found ${items.length} menu items:`);
    items.forEach(item => {
      console.log(`  - ${item.name} (restaurantId: ${item.restaurantId})`);
    });

    // Check for mismatches
    console.log('\n🔍 Checking for restaurantId mismatches:');
    for (const item of items) {
      const restaurant = restaurants.find(r => r.restaurantId === item.restaurantId || r._id.toString() === item.restaurantId);
      if (!restaurant) {
        console.log(`⚠️  Item "${item.name}" has orphaned restaurantId: ${item.restaurantId}`);
      } else {
        console.log(`✅ Item "${item.name}" belongs to ${restaurant.restaurantName}`);
      }
    }

    mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkItems();
