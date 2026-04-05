import 'cart_item.dart';
import 'food_item.dart';

class OrderItem {
  final String foodItemId;
  final String foodItemName;
  final double price;
  final int quantity;
  final String imageUrl;
  final String category;

  OrderItem({
    required this.foodItemId,
    required this.foodItemName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.category,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      foodItemId: map['foodItemId'] ?? '',
      foodItemName: map['foodItemName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodItemId': foodItemId,
      'foodItemName': foodItemName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  // Convert back to FoodItem for UI display
  FoodItem toFoodItem() {
    return FoodItem(
      id: foodItemId,
      name: foodItemName,
      description: '',
      price: price,
      imageUrl: imageUrl,
      category: category,
      restaurantId: 'default-restaurant',
    );
  }

  CartItem toCartItem() {
    return CartItem(foodItem: toFoodItem(), quantity: quantity);
  }
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String restaurantId;
  final List<OrderItem> items;
  final double totalAmount;
  final String deliveryAddress;
  final String phoneNumber;
  final String paymentMethod;
  final DateTime orderDate;
  final String status;
  final DateTime? updatedAt;

  static const List<String> statusFlow = [
    'Pending',
    'Preparing',
    'Ready',
    'Delivered',
  ];

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.orderDate,
    this.status = 'Pending',
    this.updatedAt,
  });

  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      id: data['id'] ?? data['_id'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Customer',
      restaurantId: data['restaurantId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      orderDate: data['orderDate'] != null
          ? DateTime.parse(data['orderDate'].toString())
          : DateTime.now(),
      status: data['status'] ?? 'Pending',
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'restaurantId': restaurantId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  String? get nextStatus {
    final idx = statusFlow.indexOf(status);
    if (idx >= 0 && idx < statusFlow.length - 1) {
      return statusFlow[idx + 1];
    }
    return null;
  }

  bool get isCompleted => status == 'Delivered' || status == 'Cancelled';
}
