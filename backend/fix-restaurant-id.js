const mongoose = require('mongoose');
require('dotenv').config();

const URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/smartcanteen';

async function fixRestaurantId() {
  try {
    await mongoose.connect(URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const usersCollection = db.collection('users');

    // Find the restaurant user
    const user = await usersCollection.findOne({ email: 'dominos@do.in' });
    console.log('\n📋 Current user data:');
    console.log(JSON.stringify(user, null, 2));

    if (!user) {
      console.log('❌ User not found');
      process.exit(1);
    }

    const userId = user._id.toString();
    console.log(`\n🔧 Fixing restaurantId...`);
    console.log(`   userId: ${userId}`);
    console.log(`   Old restaurantId: ${user.restaurantId}`);
    console.log(`   New restaurantId: ${userId}`);

    // Update the user with correct restaurantId
    const result = await usersCollection.updateOne(
      { email: 'dominos@do.in' },
      { $set: { restaurantId: userId } }
    );

    console.log(`\n✅ Updated ${result.modifiedCount} user(s)`);

    // Verify the update
    const updatedUser = await usersCollection.findOne({ email: 'dominos@do.in' });
    console.log('\n📋 Updated user data:');
    console.log(JSON.stringify(updatedUser, null, 2));

    console.log('\n✅ Fix complete! Now logout and login again in the app.');
    
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

fixRestaurantId();
