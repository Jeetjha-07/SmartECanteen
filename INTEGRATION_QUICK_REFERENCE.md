# SmartCanteen - Quick Integration Reference

## 🔗 Integration Points (Copy-Paste Ready)

### 1. Update menu.js Route to Filter by Restaurant

**File**: `backend/routes/menu.js`

```javascript
// Get menu items for a specific restaurant
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

// Get menu items by category and restaurant
router.get('/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const { restaurantId } = req.query;

    let query = { category, isAvailable: true };
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

### 2. Update MenuItem Schema in Models

**File**: `backend/models/MenuItem.js` - Add this field:

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
    // ... rest of fields
  },
  { timestamps: true }
);
```

---

### 3. Update Food Item Model in Flutter

**File**: `lib/models/food_item.dart` - Add field:

```dart
class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String restaurantId; // ✅ ADD THIS
  final bool isAvailable;
  final double rating;
  final int ratingCount;
  final int preparationTime;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurantId, // ✅ ADD THIS
    this.isAvailable = true,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.preparationTime = 0,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      restaurantId: json['restaurantId'] ?? '', // ✅ ADD THIS
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      preparationTime: json['preparationTime'] ?? 0,
    );
  }
}
```

---

### 4. Update Menu Service

**File**: `lib/services/menu_service.dart`

```dart
class MenuService extends ChangeNotifier {
  // ... existing code ...

  Future<void> getMenuItems({String? restaurantId, String? category}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      String url = '${ApiService.baseUrl}/menu';
      if (category != null) {
        url = '${ApiService.baseUrl}/menu/$category';
      }

      if (restaurantId != null) {
        url += url.contains('?') ? '&restaurantId=$restaurantId' : '?restaurantId=$restaurantId';
      }

      final response = await _apiService.get(url);

      if (response != null) {
        final List<dynamic> data = response is String ? jsonDecode(response) : response;
        items = (data).map((item) => FoodItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching menu items: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
```

---

### 5. Update Main.dart Routes

**File**: `lib/main.dart`

```dart
import 'package:provider/provider.dart';
import 'services/restaurant_service.dart';
import 'services/time_slot_service.dart';
import 'services/coupon_service.dart';
import 'screens/customer/shop_listing_screen.dart';
import 'screens/customer/shop_detail_screen.dart';
import 'screens/customer/time_slot_selection_screen.dart';
import 'screens/customer/coupon_application_screen.dart';
import 'screens/restaurant/restaurant_onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => RestaurantService()),
        ChangeNotifierProvider(create: (_) => TimeSlotService()),
        ChangeNotifierProvider(create: (_) => CouponService()),
        ChangeNotifierProvider(create: (_) => MenuService()),
      ],
      child: MaterialApp(
        title: 'E-Canteen',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/restaurants': (context) => const ShopListingScreen(),
          '/restaurant-onboarding': (context) => const RestaurantOnboardingScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/shop-detail') {
            final restaurant = settings.arguments as Restaurant;
            return MaterialPageRoute(
              builder: (context) => ShopDetailScreen(restaurant: restaurant),
            );
          } else if (settings.name == '/time-slot') {
            final restaurant = settings.arguments as Restaurant;
            return MaterialPageRoute(
              builder: (context) => TimeSlotSelectionScreen(restaurant: restaurant),
            );
          } else if (settings.name == '/coupon-apply') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => CouponApplicationScreen(
                restaurant: args['restaurant'],
                orderAmount: args['orderAmount'],
              ),
            );
          }
          return null;
        },
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: AppColors.primaryOrange,
          // ... rest of theme
        ),
      ),
    );
  }
}
```

---

### 6. Update Checkout Flow

**File**: `lib/screens/customer/checkout_screen.dart` (Update existing)

```dart
// In your existing checkout screen, add:

// Import the new screens at the top
import '../customer/time_slot_selection_screen.dart';
import '../customer/coupon_application_screen.dart';

// In checkout widget:
class CheckoutScreen extends StatefulWidget {
  final Restaurant restaurant;
  // ... existing fields

  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  TimeSlot? selectedTimeSlot;
  Map<String, dynamic>? couponResult;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Existing items list...
              
              // ✅ ADD: Time Slot Selection
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Delivery Time Slot'),
                  subtitle: Text(
                    selectedTimeSlot != null
                        ? '${selectedTimeSlot!.displayTime}'
                        : 'Select time slot',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimeSlotSelectionScreen(
                          restaurant: widget.restaurant,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        selectedTimeSlot = result['timeSlot'];
                      });
                    }
                  },
                ),
              ),
              
              // ✅ ADD: Coupon Application
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Coupon'),
                  subtitle: Text(
                    couponResult != null
                        ? 'Coupon Applied: -₹${couponResult!['discount']}'
                        : 'Apply coupon code',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CouponApplicationScreen(
                          restaurant: widget.restaurant,
                          orderAmount: cartTotal,
                        ),
                      ),
                    );
                    if (result != null && result['valid']) {
                      setState(() {
                        couponResult = result;
                      });
                    }
                  },
                ),
              ),
              
              // ✅ UPDATE: Total calculation
              const SizedBox(height: 16),
              ..._buildPricingBreakdown(),
              
              // ✅ UPDATE: Validation before payment
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canCheckout() ? _proceedToPayment : null,
                  child: const Text('Proceed to Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canCheckout() {
    return selectedTimeSlot != null && /* other conditions */;
  }

  List<Widget> _buildPricingBreakdown() {
    double subtotal = cartTotal;
    double discount = couponResult?['discount'] ?? 0;
    double total = subtotal - discount;

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Subtotal'),
          Text('₹${subtotal.toStringAsFixed(0)}'),
        ],
      ),
      if (couponResult != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Coupon Discount'),
            Text('-₹${discount.toStringAsFixed(0)}'),
          ],
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Delivery Charge'),
          Text('₹${widget.restaurant.deliveryCharge.toStringAsFixed(0)}'),
        ],
      ),
      const Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(
            '₹${(total + widget.restaurant.deliveryCharge).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    ];
  }

  void _proceedToPayment() {
    // Prepare order data with restaurantId, timeSlot, coupon
    final orderData = {
      'restaurantId': widget.restaurant.restaurantId, // ✅ ADD
      'items': cartItems,
      'totalAmount': _calculateTotal(),
      'couponCode': couponResult?['coupon'].code, // ✅ ADD
      'couponDiscount': couponResult?['discount'] ?? 0, // ✅ ADD
      'requestedTimeSlot': { // ✅ ADD
        'date': selectedTimeSlot!.date,
        'startTime': selectedTimeSlot!.startTime,
        'endTime': selectedTimeSlot!.endTime,
      },
      // ... existing fields
    };
    // Continue with payment...
  }
}
```

---

## ✅ Testing Checklist

```
□ Backend server running: npm run dev (in /backend)
□ MongoDB connected and running
□ Restaurant registration works
□ Can browse restaurants list
□ Can filter by cuisine/search
□ Can view restaurant details and menu
□ Can select time slot during checkout
□ Can apply valid coupon
□ Cannot apply expired/invalid coupon
□ Order created with all fields
□ Restaurant receives order with time slot
```

---

**Now your SmartCanteen app is ready to compete with Zomato! 🚀**
