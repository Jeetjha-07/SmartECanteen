import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/restaurant_service.dart';
import 'services/time_slot_service.dart';
import 'services/coupon_service.dart';
import 'services/menu_service.dart';
import 'services/payment_service.dart';
import 'config/app_environment.dart';
import 'screens/splash_screen.dart';
import 'screens/customer/shop_listing_screen.dart';
import 'screens/customer/checkout_screen.dart';
import 'screens/restaurant/restaurant_onboarding_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print environment configuration (useful for debugging)
  AppEnvironment.printEnvironmentInfo();

  // Initialize authentication (load saved JWT token if available)
  await AuthService.initializeAuth();

  // Initialize Razorpay payment service with event handlers
  PaymentService.initRazorpay(
    onSuccess: (response) {
      print('✅ Payment Success: ${response.paymentId}');
      // Payment verification is handled automatically in PaymentService
    },
    onFailure: (response) {
      print('❌ Payment Failed: ${response.code} - ${response.message}');
    },
    onWallet: (response) {
      print('💳 Wallet Selected: ${response.walletName}');
    },
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
        title: 'SmartECanteen',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/restaurants': (context) => const ShopListingScreen(),
          '/restaurant-onboarding': (context) =>
              const RestaurantOnboardingScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/checkout') {
            final restaurant = settings.arguments as dynamic;
            return MaterialPageRoute(
              builder: (context) => CheckoutScreen(restaurant: restaurant),
            );
          }
          return null;
        },
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: AppColors.primaryOrange,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryOrange,
            primary: AppColors.primaryOrange,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryOrange, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
