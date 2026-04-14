const mongoose = require('mongoose');
const Coupon = require('./models/Coupon');
const Restaurant = require('./models/Restaurant');
const { MONGODB_URI } = require('./config/database');

async function fixCoupons() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Fix 1: Set isActive to true for all coupons that have undefined isActive
    console.log('\n📋 Fixing isActive field...');
    const updateActiveResult = await Coupon.updateMany(
      { isActive: { $exists: false } },
      { $set: { isActive: true } }
    );
    console.log(`✅ Updated ${updateActiveResult.modifiedCount} coupons with isActive=true`);

    // Fix 2: Set usedCount to 0 for all coupons that have undefined usedCount
    console.log('\n📋 Fixing usedCount field...');
    const updateUsedCountResult = await Coupon.updateMany(
      { usedCount: { $exists: false } },
      { $set: { usedCount: 0 } }
    );
    console.log(`✅ Updated ${updateUsedCountResult.modifiedCount} coupons with usedCount=0`);

    // Fix 3: Verify all coupons have valid restaurantIds
    console.log('\n📋 Verifying restaurantIds...');
    const allCoupons = await Coupon.find();
    let validCoupons = 0;
    let invalidCoupons = [];

    for (const coupon of allCoupons) {
      const restaurant = await Restaurant.findOne({
        restaurantId: coupon.restaurantId,
      });

      if (!restaurant) {
        invalidCoupons.push({
          couponId: coupon._id,
          code: coupon.code,
          restaurantId: coupon.restaurantId,
        });
      } else {
        validCoupons++;
      }
    }

    console.log(`✅ Found ${validCoupons} coupons with valid restaurantIds`);

    if (invalidCoupons.length > 0) {
      console.log(
        `⚠️  Found ${invalidCoupons.length} coupons with INVALID restaurantIds:`
      );
      invalidCoupons.forEach((c) => {
        console.log(`   - Code: ${c.code}, RestaurantId: ${c.restaurantId}`);
      });

      // Optional: Delete orphaned coupons
      console.log(
        '\n❓ Delete orphaned coupons? (If yes, restart with DELETE_ORPHANED=true)'
      );
      if (process.env.DELETE_ORPHANED === 'true') {
        const deleteResult = await Coupon.deleteMany({
          _id: { $in: invalidCoupons.map((c) => c.couponId) },
        });
        console.log(`✅ Deleted ${deleteResult.deletedCount} orphaned coupons`);
      }
    }

    // Fix 4: Ensure compound index for faster lookups
    console.log('\n⚡ Creating database indexes...');
    await Coupon.collection.createIndex({
      code: 1,
      restaurantId: 1,
      isActive: 1,
    });
    console.log('✅ Index created: (code, restaurantId, isActive)');

    await Coupon.collection.createIndex({
      restaurantId: 1,
      createdAt: -1,
    });
    console.log('✅ Index created: (restaurantId, createdAt)');

    console.log('\n✅ All fixes completed successfully!');
    console.log('\n📊 Summary:');
    console.log(`   - Total coupons in database: ${allCoupons.length}`);
    console.log(`   - Valid coupons: ${validCoupons}`);
    console.log(`   - Invalid/Orphaned coupons: ${invalidCoupons.length}`);
  } catch (error) {
    console.error('❌ Error during fix:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

// Run the fix
fixCoupons();
