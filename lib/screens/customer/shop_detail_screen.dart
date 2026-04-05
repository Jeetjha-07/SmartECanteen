import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/menu_service.dart';
import '../../services/cart_service.dart';
import '../../models/restaurant.dart';
import '../../models/food_item.dart';
import '../../utils/app_colors.dart';

class ShopDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const ShopDetailScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch menu items for this restaurant
      print(
          '🏪 Shop Detail Screen - restaurantId: ${widget.restaurant.restaurantId}');
      Provider.of<MenuService>(context, listen: false)
          .getMenuItems(restaurantId: widget.restaurant.restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Header
            _buildRestaurantHeader(),
            const Divider(height: 1),

            // Menu Items
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Consumer<MenuService>(
                builder: (context, menuService, _) {
                  if (menuService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (menuService.error != null) {
                    return Center(
                      child: Text('Error: ${menuService.error}'),
                    );
                  }

                  final items = menuService.items;
                  final categories =
                      items.map((item) => item.category).toSet().toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('No items available'));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Filter
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = _selectedCategory == category ||
                                (_selectedCategory == null && index == 0);

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory =
                                        selected ? category : null;
                                  });
                                },
                                selectedColor: AppColors.primaryOrange,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Menu Items Grid
                      ..._getFilteredItems(items, categories).map(
                        (item) => _buildMenuItemCard(item),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<CartService>(
        builder: (context, cartService, _) {
          if (cartService.cartItems.isEmpty) {
            return const SizedBox();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/checkout',
                  arguments: widget.restaurant);
            },
            label: Text(
                '${cartService.cartItems.length} items - ₹${cartService.totalPrice.toStringAsFixed(0)}'),
            icon: const Icon(Icons.shopping_cart),
            backgroundColor: AppColors.primaryOrange,
          );
        },
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: widget.restaurant.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.restaurant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 80),
                        );
                      },
                    )
                  : const Icon(Icons.restaurant, size: 80),
            ),
          ),
          const SizedBox(height: 12),

          // Restaurant Info
          Text(
            widget.restaurant.restaurantName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                  '${widget.restaurant.averageRating.toStringAsFixed(1)} (${widget.restaurant.totalRatings} ratings)'),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 16, color: AppColors.primaryOrange),
              const SizedBox(width: 4),
              Text('${widget.restaurant.deliveryTime} mins'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.restaurant.description,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.restaurant.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(FoodItem item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 80,
                  width: 80,
                  color: Colors.grey[300],
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(item.imageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood),
                ),
              ),
              const SizedBox(width: 12),

              // Item Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final cartService = Provider.of<CartService>(
                                context,
                                listen: false);

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
                                        cartService
                                            .clearCartAndAddNewItem(item);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${item.name} added to new cart!'),
                                            duration:
                                                const Duration(seconds: 1),
                                            backgroundColor:
                                                AppColors.successGreen,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.add,
                                size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FoodItem> _getFilteredItems(
      List<FoodItem> items, List<String> categories) {
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return items.where((item) => item.category == _selectedCategory).toList();
  }

  void _showItemDetails(FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(item.imageUrl, fit: BoxFit.cover)
                        : const Icon(Icons.fastfood, size: 80),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(item.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(item.description, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 12),
              Text(
                '₹${item.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cartService =
                        Provider.of<CartService>(context, listen: false);

                    // Check if adding from different restaurant
                    if (cartService.isDifferentRestaurant(item)) {
                      Navigator.pop(context);
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
                                    content:
                                        Text('${item.name} added to new cart!'),
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
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                  ),
                  child: const Text('Add to Cart',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
