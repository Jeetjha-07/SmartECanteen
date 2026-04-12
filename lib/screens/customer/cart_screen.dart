import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Please login to view your cart',
                style: TextStyle(fontSize: 18, color: AppColors.textGrey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              icon: const Icon(Icons.login),
              label: const Text('Login'),
            ),
          ],
        ),
      );
    }

    return Consumer<CartService>(
      builder: (context, cartService, _) {
        if (cartService.cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Your cart is empty',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                SizedBox(height: 8),
                Text('Browse the menu and add items!',
                    style: TextStyle(color: AppColors.textGrey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Cart header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cartService.itemCount} item(s) in cart',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textGrey),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Clear Cart'),
                          content:
                              const Text('Remove all items from your cart?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                cartService.clearCart();
                                Navigator.pop(context);
                              },
                              child: const Text('Clear',
                                  style: TextStyle(color: AppColors.errorRed)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.errorRed, size: 18),
                    label: const Text('Clear',
                        style: TextStyle(color: AppColors.errorRed)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cartService.cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = cartService.cartItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                _buildCartItemImage(cartItem.foodItem.imageUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cartItem.foodItem.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${cartItem.foodItem.price.toStringAsFixed(0)} each',
                                  style: const TextStyle(
                                      color: AppColors.textGrey, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${(cartItem.foodItem.price * cartItem.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          // Quantity controls
                          Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: AppColors.primaryOrange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => cartService.updateQuantity(
                                      cartItem.foodItem.id,
                                      cartItem.quantity - 1),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.remove,
                                        size: 16,
                                        color: AppColors.primaryOrange),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text('${cartItem.quantity}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                                InkWell(
                                  onTap: () =>
                                      cartService.addItem(cartItem.foodItem),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.add,
                                        size: 16,
                                        color: AppColors.primaryOrange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () =>
                                cartService.removeItem(cartItem.foodItem.id),
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.errorRed, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom total + checkout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:',
                          style: TextStyle(color: AppColors.textGrey)),
                      Text('₹${cartService.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery:',
                          style: TextStyle(color: AppColors.textGrey)),
                      Text('FREE',
                          style: TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${cartService.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckoutScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Proceed to Checkout',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCompleteImageUrl(String relativeUrl) {
    if (relativeUrl.isEmpty) {
      print('⚠️ [Cart] Empty image URL received');
      return '';
    }
    if (relativeUrl.startsWith('http')) {
      // Already a complete URL (Cloudinary)
      print('✅ [Cart] Using complete URL: $relativeUrl');
      return relativeUrl;
    }
    // Skip /uploads/ paths (they don't exist on Render's ephemeral filesystem)
    if (relativeUrl.startsWith('/uploads')) {
      print('⚠️ [Cart] Skipping ephemeral /uploads/ path: $relativeUrl');
      return ''; // Show placeholder instead
    }
    // Use server base URL (not /api) for static files
    final completeUrl = '${ApiService.serverBaseUrl}$relativeUrl';
    print('🖼️ [Cart] Building URL: $relativeUrl -> $completeUrl');
    return completeUrl;
  }

  Widget _buildCartItemImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 65,
        height: 65,
        color: Colors.grey[200],
        child: const Icon(Icons.restaurant, color: Colors.grey),
      );
    }

    final completeUrl = _getCompleteImageUrl(imageUrl);

    if (completeUrl.isEmpty) {
      return Container(
        width: 65,
        height: 65,
        color: Colors.grey[200],
        child: const Icon(Icons.restaurant, color: Colors.grey),
      );
    }

    if (!completeUrl.startsWith('http')) {
      return Container(
        width: 65,
        height: 65,
        color: Colors.grey[200],
        child: const Icon(Icons.restaurant, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: completeUrl,
      width: 65,
      height: 65,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        width: 65,
        height: 65,
        color: Colors.grey[200],
        child: const Icon(Icons.restaurant, color: Colors.grey),
      ),
    );
  }
}
