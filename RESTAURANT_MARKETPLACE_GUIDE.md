# SmartCanteen Restaurant Marketplace - Integration Guide

## 📚 What Has Been Built

Your SmartCanteen app now has a complete **Zomato/Swiggy-like restaurant marketplace system** with:

### ✅ Backend Infrastructure
- **3 new MongoDB models**: Restaurant, Coupon, TimeSlot
- **3 new API routes**: /restaurants, /coupons, /timeslots
- **Firebase authentication** on all restaurant endpoints

### ✅ Flutter Frontend
- **Customer Screens**: Shop listing, detail view, time slot selection, coupon application
- **Restaurant Screens**: Complete onboarding wizard (5 steps)
- **Services**: Restaurant, TimeSlot, Coupon services with full API integration

---

## 🔧 Integration Checklist

### 1. **Update Menu Service (lib/services/menu_service.dart)**
Add filter by restaurantId:
```dart
Future<void> getMenuItems({String? restaurantId}) async {
  String url = '${ApiService.baseUrl}/menu';
  if (restaurantId != null) {
    url += '?restaurantId=$restaurantId';
  }
  // ... rest of code
}
```

### 2. **Update Menu API Route (backend/routes/menu.js)**
Allow filtering by restaurantId:
```javascript
router.get('/', async (req, res) => {
  const { restaurantId } = req.query;
  let query = { isAvailable: true };
  if (restaurantId) query.restaurantId = restaurantId;
  const items = await MenuItem.find(query);
  res.json(items);
});
```

### 3. **Update Cart Service (lib/services/cart_service.dart)**
Prevent mixing items from different restaurants:
```dart
void addItem(FoodItem item) {
  if (currentRestaurantId != null && currentRestaurantId != item.restaurantId) {
    throw Exception('Cannot add items from different restaurants');
  }
  currentRestaurantId = item.restaurantId;
  // ... rest of add logic
}
```

### 4. **Add Routes to Main Navigation (lib/main.dart)**
```dart
MaterialApp(
  routes: {
    '/home': (context) => const HomeScreen(),
    '/restaurants': (context) => const ShopListingScreen(),
    '/restaurant-onboarding': (context) => const RestaurantOnboardingScreen(),
    '/time-slot': (context) => TimeSlotSelectionScreen(
      restaurant: ModalRoute.of(context)!.settings.arguments as Restaurant,
    ),
    '/coupon-apply': (context) => CouponApplicationScreen(
      restaurant: ModalRoute.of(context)!.settings.arguments as Restaurant,
      orderAmount: 0,
    ),
  },
)
```

### 5. **Add Providers to Main (lib/main.dart)**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CartService()),
    ChangeNotifierProvider(create: (_) => RestaurantService()),
    ChangeNotifierProvider(create: (_) => TimeSlotService()),
    ChangeNotifierProvider(create: (_) => CouponService()),
    ChangeNotifierProvider(create: (_) => MenuService()),
  ],
  child: MaterialApp(...)
)
```

### 6. **Update MenuItem Model (lib/models/food_item.dart)**
Add restaurantId field:
```dart
class FoodItem {
  final String restaurantId; // Add this
  // ... existing fields
}
```

### 7. **Update Order Model Entry Point**
When creating an order, include:
```dart
final order = {
  'customerId': userId,
  'restaurantId': selectedRestaurant.restaurantId, // NEW
  'items': cartItems,
  'totalAmount': total,
  'couponCode': appliedCoupon?.code, // NEW
  'couponDiscount': discountAmount, // NEW
  'requestedTimeSlot': selectedTimeSlot, // NEW
  // ... other fields
};
```

### 8. **Create Restaurant Management Screen (Optional)**
For restaurant owners to see their dashboard:
```
lib/screens/restaurant/
  └── restaurant_dashboard_screen.dart
      ├── Orders by time slot
      ├── Coupon management
      └── Time slot statistics
```

---

## 🎯 User Flows

### Customer Flow
1. **Home Screen** → Link to "Browse Restaurants"
2. **Shop Listing** → See all restaurants with filters
3. **Shop Detail** → View restaurant & select items
4. **Cart** → Review items
5. **Checkout** 
   - Select Time Slot
   - Apply Coupon (optional)
   - Pay
   - Order confirmed for selected time slot

### Restaurant Owner Flow
1. **Sign Up** with "Restaurant" role
2. **Restaurant Onboarding** → Register 5-step form
3. **Restaurant Dashboard** → Manage:
   - Create coupons
   - View/manage time slots
   - Monitor orders by time slot
   - Update operating hours & capacity

---

## 📱 Screen Integration Points

### Existing Screens to Update

**Splash/Home Screen**: Add "Browse Restaurants" button
```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/restaurants'),
  child: const Text('Browse Restaurants'),
)
```

**Checkout Screen**: Add before payment
```dart
// Select time slot
final slotResult = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TimeSlotSelectionScreen(restaurant: restaurant),
  ),
);

// Apply coupon
final couponResult = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CouponApplicationScreen(
      restaurant: restaurant,
      orderAmount: total,
    ),
  ),
);
```

---

## 🗄️ Database Setup

Make sure your MongoDB has these collections created:
```javascript
// These will auto-create on first insert, but you can pre-create:
db.createCollection('restaurants');
db.createCollection('coupons');
db.createCollection('timeslots');
```

---

## 🔐 Authentication Flows

### Restaurant Registration
1. User signs up with email/password (Firebase)
2. Navigates to registration screen
3. Completes 5-step onboarding
4. User role changed to "restaurant"
5. Restaurant entry created in MongoDB

### Customer Checkout
1. Selects time slot → validated with capacity
2. Applies coupon → validated with min order, expiry, usage limits
3. Order created with all references
4. Webhook/notification sent to restaurant for selected time slot

---

## ⚙️ Configuration

### Time Slot Duration
Default: 15 minutes (configurable per restaurant)
- Can be changed during onboarding
- Or updated in restaurant dashboard

### Coupon Types
- **Percentage**: `discountType: 'percentage'`, e.g., 20% off
- **Fixed**: `discountType: 'fixed'`, e.g., ₹50 off

### Coupon Constraints
- Minimum order value
- Maximum uses globally
- Max uses per user
- Time-based validity (start/end date)

---

## 🚀 Deployment Checklist

- [ ] Update Menu API to accept restaurantId
- [ ] Link MenuItem model to Restaurant
- [ ] Add Provider dependencies for new services
- [ ] Add routes to Navigator
- [ ] Update Checkout flow with time slot selection
- [ ] Add coupon application in checkout
- [ ] Add "Browse Restaurants" to home screen
- [ ] Test complete user flow end-to-end
- [ ] Test restaurant registration flow
- [ ] Test coupon validation with edge cases
- [ ] Test time slot capacity limits

---

## 📞 API Summary

### All APIs require MongoDB connection!
Check backend server is running: `npm run dev` in `/backend` folder

### Test with Postman
1. Register restaurant (with valid Firebase token)
2. Create coupon
3. Generate time slots
4. Get available slots
5. Validate coupon
6. Create order with all fields

---

## 📝 Files Created

### Backend
```
backend/models/
  ├── Restaurant.js ✓
  ├── Coupon.js ✓
  └── TimeSlot.js ✓

backend/routes/
  ├── restaurants.js ✓
  ├── coupons.js ✓
  └── timeslots.js ✓
```

### Frontend
```
lib/models/
  ├── restaurant.dart ✓
  ├── time_slot.dart ✓
  └── coupon.dart ✓

lib/services/
  ├── restaurant_service.dart ✓
  ├── time_slot_service.dart ✓
  └── coupon_service.dart ✓

lib/screens/customer/
  ├── shop_listing_screen.dart ✓
  ├── shop_detail_screen.dart ✓
  ├── time_slot_selection_screen.dart ✓
  └── coupon_application_screen.dart ✓

lib/screens/restaurant/
  └── restaurant_onboarding_screen.dart ✓
```

---

**You now have a complete restaurant marketplace system! 🎉**
Ready to integrate into your existing app?
