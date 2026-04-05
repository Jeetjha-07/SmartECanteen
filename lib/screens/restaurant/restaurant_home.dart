import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'restaurant_orders_screen.dart';
import 'restaurant_menu_screen.dart';
import 'restaurant_analytics_screen.dart';
import 'restaurant_reviews_screen.dart';
import 'restaurant_time_slots_screen.dart';
import 'restaurant_coupons_screen.dart';
import 'restaurant_shop_registration_screen.dart';
import '../splash_screen.dart';

class RestaurantHome extends StatefulWidget {
  const RestaurantHome({super.key});

  @override
  State<RestaurantHome> createState() => _RestaurantHomeState();
}

class _RestaurantHomeState extends State<RestaurantHome> {
  int _selectedIndex = 0;
  bool _shopRegistered = true; // Assume registered by default
  String? _restaurantId;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkShopRegistration();
    _initializeScreens();
  }

  void _initializeScreens() {
    final user = AuthService.currentUser;
    _restaurantId = user?.restaurantId;

    print('\n🏪 RestaurantHome: Initialize Screens');
    print('   User: ${user?.email}');
    print('   User.uid: ${user?.uid}');
    print('   User.restaurantId: ${user?.restaurantId}');
    print('   _restaurantId (local): $_restaurantId');
    print('   isRestaurant: ${user?.isRestaurant}');

    if (_restaurantId == null || _restaurantId!.isEmpty) {
      print('   ⚠️ WARNING: restaurantId is null or empty!');
    }

    _screens = [
      const RestaurantOrdersScreen(),
      const RestaurantMenuScreen(),
      const RestaurantTimeSlotsScreen(),
      const RestaurantAnalyticsScreen(),
      RestaurantReviewsScreen(restaurantId: _restaurantId ?? ''),
      const RestaurantCouponsScreen(),
    ];

    print('   Screens initialized with restaurantId: $_restaurantId');
  }

  // Check if restaurant has registered their shop
  Future<void> _checkShopRegistration() async {
    final user = AuthService.currentUser;
    // If restaurantId is not set, shop is not registered yet
    if (user != null && user.restaurantId == null) {
      setState(() => _shopRegistered = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If shop not registered, show registration screen
    if (!_shopRegistered) {
      return const RestaurantShopRegistrationScreen();
    }

    const titles = [
      'Live Orders',
      'Menu Management',
      'Time Slots',
      'Analytics',
      'Reviews',
      'Coupons'
    ];
    const icons = [
      Icons.receipt_long,
      Icons.restaurant_menu,
      Icons.schedule,
      Icons.bar_chart,
      Icons.star,
      Icons.local_offer,
    ];

    print(
        '\n🏪️ RestaurantHome: Build() - Tab Index: $_selectedIndex (${titles[_selectedIndex]})');
    print('   restaurantId: $_restaurantId');
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      print(
          '   ⚠️ CRITICAL: restaurantId is NULL/EMPTY! Reviews will not load!');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.restaurantPrimary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.storefront, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('E-Canteen Dashboard',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(titles[_selectedIndex],
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed),
                      child: const Text('Logout')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: AppColors.restaurantPrimary,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: AppColors.restaurantPrimary,
          selectedItemColor: AppColors.primaryOrange,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: [
            BottomNavigationBarItem(icon: Icon(icons[0]), label: titles[0]),
            BottomNavigationBarItem(icon: Icon(icons[1]), label: titles[1]),
            BottomNavigationBarItem(icon: Icon(icons[2]), label: titles[2]),
            BottomNavigationBarItem(icon: Icon(icons[3]), label: titles[3]),
            BottomNavigationBarItem(icon: Icon(icons[4]), label: titles[4]),
            BottomNavigationBarItem(icon: Icon(icons[5]), label: titles[5]),
          ],
        ),
      ),
    );
  }
}
