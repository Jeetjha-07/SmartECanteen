import 'food_item.dart';

class CartItem {
  final FoodItem foodItem;
  int quantity;

  CartItem({required this.foodItem, this.quantity = 1});

  Map<String, dynamic> toMap() {
    return {
      'foodItemId': foodItem.id,
      'foodItemName': foodItem.name,
      'price': foodItem.price,
      'quantity': quantity,
      'imageUrl': foodItem.imageUrl,
      'category': foodItem.category,
    };
  }
}
