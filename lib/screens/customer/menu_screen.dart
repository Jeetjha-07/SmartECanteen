import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/food_item.dart';
import '../../services/menu_service.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load menu items once when screen opens
    Future.microtask(() {
      if (mounted) {
        context.read<MenuService>().getMenuItems();
      }
    });
  }

  Future<void> _refreshMenu() async {
    context.read<MenuService>().getMenuItems();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Items'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMenu,
        color: AppColors.primaryOrange,
        child: Consumer2<MenuService, CartService>(
          builder: (context, menuService, cartService, _) {
            // Handle loading and error states
            if (menuService.isLoading && menuService.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (menuService.error != null && menuService.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.errorRed, size: 48),
                    const SizedBox(height: 12),
                    Text('Error: ${menuService.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => menuService.getMenuItems(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final allItems = menuService.items;

            // Extract categories
            final categories = ['All'];
            for (final item in allItems) {
              if (!categories.contains(item.category)) {
                categories.add(item.category);
              }
            }

            // Filter items
            var filteredItems = allItems;
            if (_selectedCategory != 'All') {
              filteredItems = filteredItems
                  .where((item) => item.category == _selectedCategory)
                  .toList();
            }
            if (_searchQuery.isNotEmpty) {
              filteredItems = filteredItems
                  .where((item) =>
                      item.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      item.description
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                  .toList();
            }

            return Column(
              children: [
                // Search Bar
                Container(
                  color: AppColors.primaryOrange,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search menu...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Category chips
                Container(
                  height: 50,
                  color: Colors.white,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDark,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                          backgroundColor: Colors.grey[100],
                          selectedColor: AppColors.primaryOrange,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),

                // Items list
                Expanded(
                  child: filteredItems.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.no_food, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No items found',
                                  style: TextStyle(
                                      fontSize: 18, color: AppColors.textGrey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final qty = cartService.getQuantity(item.id);
                            return _buildMenuCard(
                                context, item, qty, cartService);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, FoodItem item, int qty, CartService cartService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Food image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(item.description,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Add / Quantity controls
            qty == 0
                ? ElevatedButton(
                    onPressed: () {
                      if (!AuthService.isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                        return;
                      }

                      // Check if adding from different restaurant
                      if (cartService.isDifferentRestaurant(item)) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Switch Restaurant?'),
                            content: const Text(
                              'Your cart contains items from another restaurant. '
                              'Starting a new order will clear your current cart.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  cartService.clearCartAndAddNewItem(item);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${item.name} added to new cart!',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: AppColors.successGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Switch'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        cartService.addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${item.name} added to cart!'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add'),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () =>
                              cartService.updateQuantity(item.id, qty - 1),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.remove,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$qty',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        InkWell(
                          onTap: () => cartService.addItem(item),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child:
                                Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
