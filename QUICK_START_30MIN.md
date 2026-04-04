# 🚀 Quick Start: Get This Running in 30 Minutes

## ⏱️ Timeline
- **5 min** - Update menu.js
- **5 min** - Update MenuItem model
- **5 min** - Update main.dart providers & routes
- **5 min** - Import services in checkout
- **5 min** - Test everything

---

## ✅ Step-by-Step (Copy & Paste)

### Step 1: Update Menu API (5 min)

**File: `backend/routes/menu.js`**

Replace the GET '/' route with:
```javascript
router.get('/', async (req, res) => {
  try {
    const { restaurantId } = req.query;
    let query = { isAvailable: true };

    if (restaurantId) {
      query.restaurantId = restaurantId;
    }

    const items = await MenuItem.find(query).lean();
    res.json(items);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

### Step 2: Update MenuItem Model (5 min)

**File: `backend/models/MenuItem.js`**

Add `restaurantId` to schema:
```javascript
const menuItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    description: String,
    price: { type: Number, required: true },
    imageUrl: String,
    category: { type: String, required: true },
    restaurantId: { type: String, required: true }, // ✅ ADD THIS
    isAvailable: { type: Boolean, default: true },
    preparationTime: Number,
    rating: { type: Number, default: 0, min: 0, max: 5 },
    ratingCount: { type: Number, default: 0 },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);
```

---

### Step 3: Update main.dart (5 min)

**File: `lib/main.dart`**

Add imports at the top:
```dart
import 'services/restaurant_service.dart';
import 'services/time_slot_service.dart';
import 'services/coupon_service.dart';
import 'screens/customer/shop_listing_screen.dart';
import 'screens/customer/shop_detail_screen.dart';
import 'screens/restaurant/restaurant_onboarding_screen.dart';
```

Replace MultiProvider with:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CartService()),
    ChangeNotifierProvider(create: (_) => RestaurantService()),
    ChangeNotifierProvider(create: (_) => TimeSlotService()),
    ChangeNotifierProvider(create: (_) => CouponService()),
    ChangeNotifierProvider(create: (_) => MenuService()),
  ],
```

Add routes to MaterialApp:
```dart
MaterialApp(
  // ... existing code ...
  routes: {
    '/restaurants': (context) => const ShopListingScreen(),
    '/restaurant-onboarding': (context) => const RestaurantOnboardingScreen(),
  },
  // ... existing code ...
)
```

---

### Step 4: Connect to Home Screen (5 min)

**File: Your existing home/landing screen**

Add button to browse restaurants:
```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/restaurants'),
  child: const Text('🏪 Browse Restaurants'),
)
```

---

### ✅ Done! Now Test

1. **Start Backend**
```bash
cd backend
npm run dev
```

2. **Run Flutter App**
```bash
flutter pub get
flutter run
```

3. **Test Flow**
   - Tap "Browse Restaurants"
   - See list of restaurants (or empty if none registered)
   - Tap "Register Restaurant" → Complete 5-step form
   - Create new user as restaurant → Complete registration
   - Go back → Should see your restaurant
   - Tap restaurant → See menu items (or empty)
   - Add menu item with restaurantId → See in list

---

## 🧪 Testing Scenarios

### Scenario 1: Register Restaurant
```
1. Sign in as new user (email: restaurant1@test.com)
2. Tap "Register Restaurant" 
3. Fill Step 1-5 of onboarding
4. Complete registration
5. Log out & log in as customer
6. Browse restaurants → Should see your restaurant
```

### Scenario 2: Apply Coupon
```
1. Create coupon as restaurant owner
2. Log in as customer
3. Add items to cart from that restaurant
4. Go to checkout
5. Tap "Apply Coupon"
6. Enter coupon code
7. Should see discount applied
```

### Scenario 3: Select Time Slot
```
1. Add items to cart
2. Go to checkout
3. Tap "Select Time Slot"
4. Pick tomorrow's date
5. Pick a time slot
6. Should confirm selection
```

---

## 🐛 Troubleshooting

### "Restaurant not found"
- Make sure you registered as restaurant role
- Check restaurantId is being saved correctly

### "No time slots available"
- Time slots need to be generated
- Call: `POST /api/timeslots/generate?date=2024-04-03`
- Requires operating hours set

### "Coupon invalid"
- Check coupon hasn't expired
- Check min order value requirement
- Check max uses not exceeded

### API returns 503
- MongoDB not running
- Start mongod first: `mongod`

### App crashes on restaurant screen
- Check all imports are correct
- Run `flutter pub get`
- Clean build: `flutter clean && flutter pub get`

---

## 📱 What You'll See

### Restaurant List (Customers)
- List of all registered restaurants
- Filter by cuisine
- Search by name
- Sort by rating or delivery time
- Tap to see menu

### Time Slot Selection
- Calendar picker
- Time slots for selected day
- Shows capacity remaining
- Select one slot

### Coupon Application
- Enter coupon code
- Shows discount amount
- Preview final price
- List of available coupons

### Restaurant Onboarding
- Step 1: Basic info
- Step 2: Location & delivery
- Step 3: Select cuisines
- Step 4: Time slot capacity
- Step 5: Bank details

---

## 💡 Pro Tips

1. **Use Postman** to test APIs before UI
2. **Seed time slots** before customer checkout
3. **Create test coupons** with future dates
4. **Check console logs** for API errors
5. **Use Firebase emulator** for faster testing

---

## 📚 Reference Files

- Integration guide: `INTEGRATION_QUICK_REFERENCE.md`
- Architecture: `IMPLEMENTATION_SUMMARY.md`
- Complete features: `RESTAURANT_MARKETPLACE_GUIDE.md`
- Comparison: `FEATURE_COMPARISON.md`

---

## 🎯 Success Checklist

- [ ] Backend server running (`npm run dev`)
- [ ] MongoDB connected
- [ ] Flutter app compiling without errors
- [ ] Can tap "Browse Restaurants"
- [ ] Can see restaurant list screen
- [ ] Can register as restaurant
- [ ] Registered restaurant appears in list
- [ ] Can create coupon
- [ ] Can select time slot
- [ ] Can apply coupon in checkout

**When all checked: You're ready to deploy! 🚀**

---

## 🎉 Congratulations!

You now have a **production-grade restaurant marketplace system** similar to Zomato/Swiggy!

### Next Steps (Optional)
- Add restaurant dashboard
- Implement payment integration
- Add order tracking
- Create mobile notifications
- Add user ratings & reviews

**Start integrating and have fun! 🚀**
