require('dotenv').config();
const mongoose = require('mongoose');
const MenuItem = require('./models/MenuItem');

async function updateMenuItems() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Get all existing menu items
    const items = await MenuItem.find({});
    console.log(`Found ${items.length} menu items`);

    // Sample restaurant IDs
    const sampleRestaurantIds = [
      'sample-restaurant-1', // Biryani House
      'sample-restaurant-2', // Sweets
      'sample-restaurant-3', // Tandoori
      'sample-restaurant-4', // Choco
      'sample-restaurant-5', // Spice Kitchen
    ];

    // Distribute items across restaurants
    let updated = 0;
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const restaurantId = sampleRestaurantIds[i % sampleRestaurantIds.length];
      
      item.restaurantId = restaurantId;
      await item.save();
      console.log(`✓ Updated "${item.name}" -> ${restaurantId}`);
      updated++;
    }

    console.log(`\n✅ Updated ${updated} menu items to use sample restaurants`);

    // Verify by getting items from first restaurant
    const testItems = await MenuItem.find({ restaurantId: 'sample-restaurant-1' });
    console.log(`\n📋 Items in "The Biryani House": ${testItems.length}`);
    testItems.forEach(item => {
      console.log(`  - ${item.name} (${item.category})`);
    });

    console.log('\n✨ Menu items updated successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Update failed:', error);
    process.exit(1);
  }
}

updateMenuItems();
