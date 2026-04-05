import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class OrderService {
  // Place a new order via API
  static Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String deliveryAddress,
    required String phoneNumber,
    required String paymentMethod,
    required String restaurantId,
    String? timeSlotId,
    String? couponCode,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Not logged in'};
      }

      final orderItems = cartItems
          .map((ci) => {
                'foodItemId': ci.foodItem.id,
                'foodItemName': ci.foodItem.name,
                'price': ci.foodItem.price,
                'quantity': ci.quantity,
                'imageUrl': ci.foodItem.imageUrl,
                'category': ci.foodItem.category,
              })
          .toList();

      final orderData = {
        'items': orderItems,
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'phoneNumber': phoneNumber,
        'paymentMethod': paymentMethod,
        'restaurantId': restaurantId,
        if (timeSlotId != null) 'timeSlotId': timeSlotId,
        if (couponCode != null) 'couponCode': couponCode,
      };
      final response = await ApiService.createOrder(orderData);

      if (response['order'] != null) {
        return {'success': true, 'orderId': response['order']['_id']};
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to create order'
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get customer's orders
  static Future<List<Order>> getCustomerOrders() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return [];

      final response = await ApiService.getUserOrders();
      return response.map((item) => Order.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching customer orders: $e');
      return [];
    }
  }

  // Get all orders for restaurant (fetch from backend - filtered by users' restaurant)
  static Future<List<Order>> getAllOrders() async {
    try {
      // Fetch all orders from backend
      final response = await ApiService.getAllOrders();
      return response.map((item) => Order.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching all orders: $e');
      return [];
    }
  }

  // Get orders for a specific restaurant
  static Future<List<Order>> getRestaurantOrders(String restaurantId) async {
    try {
      print(
          '\n📊 Analytics: Fetching orders for restaurantId: "$restaurantId"');

      // Fetch all orders from backend
      final allOrders = await getAllOrders();

      print('📊 Analytics: Backend returned ${allOrders.length} orders');

      // ✅ Filter orders by the specified restaurantId
      final filteredOrders = allOrders
          .where((order) => order.restaurantId == restaurantId)
          .toList();

      print(
          '📊 Analytics: After filtering for restaurantId "$restaurantId": ${filteredOrders.length} orders');

      if (filteredOrders.isEmpty) {
        print('   ⚠️ No orders found for restaurantId: $restaurantId');
        print(
            '   Available restaurantIds in orders: ${allOrders.map((o) => o.restaurantId).toSet()}');
        return [];
      }

      // Debug: Print details to verify data
      print('   Sample orders for this restaurant:');
      for (var order in filteredOrders.take(3)) {
        print(
            '   - Order: ${order.id} | Amount: ₹${order.totalAmount} | Status: ${order.status} | RestaurantId: ${order.restaurantId}');
      }

      return filteredOrders;
    } catch (e) {
      print('❌ Error fetching restaurant orders: $e');
      return [];
    }
  }

  // Stream of ALL orders (polls every 3 seconds)
  static Stream<List<Order>> getAllOrdersStream() {
    return Stream.periodic(const Duration(seconds: 3), (_) {
      return getAllOrders();
    }).asyncExpand((future) => future.asStream());
  }

  // Stream of active (non-completed) orders
  static Stream<List<Order>> getActiveOrdersStream() {
    return Stream.periodic(const Duration(seconds: 3), (_) async {
      final orders = await getAllOrders();
      return orders
          .where((o) =>
              o.status == 'Pending' ||
              o.status == 'Preparing' ||
              o.status == 'Ready')
          .toList();
    }).asyncExpand((future) => future.asStream());
  }

  // Update order status via API
  static Future<bool> updateOrderStatus(
      String orderId, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(orderId, newStatus);
      print('✅ Order status updated to: $newStatus');
      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  // Delete order via API (restaurant only)
  static Future<bool> deleteOrder(String orderId) async {
    try {
      print('🗑️ Deleting order: $orderId');
      final response = await ApiService.deleteOrder(orderId);
      if (response['success'] == true) {
        print('✅ Order deleted successfully: $orderId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting order: $e');
      return false;
    }
  }

  // Get monthly analytics
  static Future<List<Map<String, dynamic>>> getMonthlyAnalytics() async {
    try {
      // Requires backend analytics endpoint
      return [];
    } catch (e) {
      print('Error fetching analytics: $e');
      return [];
    }
  }

  // Get top selling items
  static Future<List<Map<String, dynamic>>> getTopSellingItems(
      {int limit = 5}) async {
    try {
      // Requires backend analytics endpoint
      return [];
    } catch (e) {
      print('Error fetching top items: $e');
      return [];
    }
  }
}
