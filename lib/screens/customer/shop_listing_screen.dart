import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/restaurant_service.dart';
import '../../models/restaurant.dart';
import '../../utils/app_colors.dart';
import 'shop_detail_screen.dart';

class ShopListingScreen extends StatefulWidget {
  const ShopListingScreen({super.key});

  @override
  State<ShopListingScreen> createState() => _ShopListingScreenState();
}

class _ShopListingScreenState extends State<ShopListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  String? _selectedCuisine;
  String? _sortBy;

  final List<String> cuisines = [
    'All',
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'American',
    'Fast Food',
    'Bakery',
    'Cafe',
  ];

  final List<String> sortOptions = [
    'Default',
    'Highest Rated',
    'Fastest Delivery',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantService>(context, listen: false).getRestaurants();
    });
  }

  void _applyFilters() {
    final restaurantService =
        Provider.of<RestaurantService>(context, listen: false);
    restaurantService.getRestaurants(
      city: _selectedCity,
      cuisine: _selectedCuisine != null && _selectedCuisine != 'All'
          ? _selectedCuisine
          : null,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      sortBy: _sortBy == 'Highest Rated'
          ? 'rating'
          : (_sortBy == 'Fastest Delivery' ? 'deliveryTime' : null),
    );
  }

  Future<void> _refreshRestaurants() async {
    _applyFilters();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Restaurants'),
        elevation: 0,
        backgroundColor: AppColors.primaryOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRestaurants,
        color: AppColors.primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search restaurants...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 16),

                // Cuisine Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cuisines.length,
                    itemBuilder: (context, index) {
                      final cuisine = cuisines[index];
                      final isSelected = _selectedCuisine == cuisine ||
                          (cuisine == 'All' && _selectedCuisine == null);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cuisine),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCuisine = selected ? cuisine : null;
                            });
                            _applyFilters();
                          },
                          selectedColor: AppColors.primaryOrange,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Restaurants List
                Consumer<RestaurantService>(
                  builder: (context, restaurantService, _) {
                    if (restaurantService.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (restaurantService.error != null) {
                      return Center(
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Error: ${restaurantService.error}'),
                          ],
                        ),
                      );
                    }

                    if (restaurantService.restaurants.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryOrange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: AppColors.primaryOrange,
                                  size: 80,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Coming Soon!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Restaurants are registering and setting up their menus.\nCheck back soon!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryOrange.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primaryOrange
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppColors.primaryOrange,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Pull to refresh',
                                      style: TextStyle(
                                        color: AppColors.primaryOrange,
                                        fontWeight: FontWeight.w500,
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

                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: restaurantService.restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurantService.restaurants[index];
                        return _buildRestaurantCard(restaurant);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailScreen(restaurant: restaurant),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        borderOnForeground: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: restaurant.imageUrl.isNotEmpty
                    ? Image.network(
                        restaurant.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.restaurant, size: 50),
                          );
                        },
                      )
                    : const Icon(Icons.restaurant, size: 50),
              ),
            ),
            // Restaurant Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.restaurantName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Cuisines
                  Text(
                    restaurant.cuisineTypes.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Delivery Info
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 14, color: AppColors.primaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.deliveryTime} mins',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.local_shipping,
                          size: 14, color: AppColors.primaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        '₹${restaurant.deliveryCharge.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (restaurant.minOrderValue > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Min order: ₹${restaurant.minOrderValue}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[600],
                        ),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...sortOptions.map(
              (option) => RadioListTile<String?>(
                title: Text(option),
                value: option == 'Default' ? null : option,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
