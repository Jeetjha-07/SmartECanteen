import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _cartItems = [];
  String? _currentRestaurantId;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  String? get currentRestaurantId => _currentRestaurantId;

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _cartItems.fold(
      0, (sum, item) => sum + (item.foodItem.price * item.quantity));

  bool isInCart(String foodItemId) {
    return _cartItems.any((item) => item.foodItem.id == foodItemId);
  }

  int getQuantity(String foodItemId) {
    final item = _cartItems.cast<CartItem?>().firstWhere(
          (item) => item?.foodItem.id == foodItemId,
          orElse: () => null,
        );
    return item?.quantity ?? 0;
  }

  /// Check if adding this item would require clearing the cart (different restaurant)
  bool isDifferentRestaurant(FoodItem foodItem) {
    if (_cartItems.isEmpty) return false;
    return _cartItems.first.foodItem.restaurantId != foodItem.restaurantId;
  }

  void addItem(FoodItem foodItem) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.foodItem.id == foodItem.id);
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(CartItem(foodItem: foodItem));
    }
    _currentRestaurantId = foodItem.restaurantId;
    notifyListeners();
  }

  void clearCartAndAddNewItem(FoodItem foodItem) {
    _cartItems.clear();
    _cartItems.add(CartItem(foodItem: foodItem));
    _currentRestaurantId = foodItem.restaurantId;
    notifyListeners();
  }

  void removeItem(String foodItemId) {
    _cartItems.removeWhere((item) => item.foodItem.id == foodItemId);
    notifyListeners();
  }

  void updateQuantity(String foodItemId, int quantity) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.foodItem.id == foodItemId);
    if (existingIndex >= 0) {
      if (quantity > 0) {
        _cartItems[existingIndex].quantity = quantity;
      } else {
        _cartItems.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
