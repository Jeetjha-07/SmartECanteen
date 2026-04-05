import 'order_service.dart';
import 'review_service.dart';

class AnalyticsService {
  /// Get basic analytics for a specific restaurant
  static Future<Map<String, dynamic>> getBasicAnalytics(
      String restaurantId) async {
    try {
      print('📊 Analytics: Loading for restaurantId: $restaurantId');

      // Gather data filtered to this restaurant only
      final allOrders = await OrderService.getRestaurantOrders(restaurantId);
      final restaurantReviews =
          await ReviewService.getRestaurantReviews(restaurantId);

      print('📊 Analytics: Total orders fetched: ${allOrders.length}');
      print('📊 Analytics: Total reviews fetched: ${restaurantReviews.length}');

      // Debug: print details of each order
      for (var order in allOrders) {
        print(
            '  - Order: ${order.id}, Amount: ₹${order.totalAmount}, Status: ${order.status}, RestaurantId: ${order.restaurantId}');
      }

      // Debug: print details of reviews
      for (var review in restaurantReviews) {
        print(
            '  - Review: ${review.id}, Rating: ${review.rating}, Customer: ${review.customerId}');
      }

      // Calculate quick stats for this restaurant only
      // Revenue = All orders except Pending (not confirmed) and Cancelled (rejected)
      final totalRevenue = allOrders
          .where((o) => o.status != 'Pending' && o.status != 'Cancelled')
          .fold(0.0, (sum, o) => sum + o.totalAmount);

      final preparingCount =
          allOrders.where((o) => o.status == 'Preparing').length;
      final readyCount = allOrders.where((o) => o.status == 'Ready').length;
      final deliveredCount =
          allOrders.where((o) => o.status == 'Delivered').length;
      final pendingCount = allOrders.where((o) => o.status == 'Pending').length;
      final cancelledCount =
          allOrders.where((o) => o.status == 'Cancelled').length;

      print('📊 Analytics: Revenue Summary');
      print('  - Total Orders: ${allOrders.length}');
      print('  - Preparing: $preparingCount');
      print('  - Ready: $readyCount');
      print('  - Delivered: $deliveredCount');
      print('  - Pending: $pendingCount');
      print('  - Cancelled: $cancelledCount');
      print('  - Revenue (Preparing+Ready+Delivered): ₹$totalRevenue');
      print('  - Total Reviews: ${restaurantReviews.length}');

      // Calculate average rating for this restaurant
      double avgRating = 0.0;
      if (restaurantReviews.isNotEmpty) {
        avgRating =
            restaurantReviews.map((r) => r.rating).reduce((a, b) => a + b) /
                restaurantReviews.length;
        print('  - Average Rating: ${avgRating.toStringAsFixed(2)} ⭐');
      }

      // Calculate rating distribution for this restaurant
      final Map<int, int> ratingDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final review in restaurantReviews) {
        final star = review.rating.round();
        ratingDist[star] = (ratingDist[star] ?? 0) + 1;
      }

      // Calculate average order value (for all accepted orders)
      final revenueGeneratingOrders = allOrders
          .where((o) => o.status != 'Pending' && o.status != 'Cancelled')
          .length;
      final avgOrderValue = revenueGeneratingOrders > 0
          ? totalRevenue / revenueGeneratingOrders
          : 0.0;

      return {
        'totalOrders': allOrders.length,
        'totalRevenue': totalRevenue,
        'avgOrderValue': avgOrderValue,
        'preparingOrders': preparingCount,
        'readyOrders': readyCount,
        'deliveredOrders': deliveredCount,
        'pendingOrders': pendingCount,
        'cancelledOrders': cancelledCount,
        'cancelRate': allOrders.isNotEmpty
            ? (cancelledCount / allOrders.length * 100).toStringAsFixed(1)
            : '0',
        'avgRating': avgRating,
        'ratingDistribution': ratingDist,
        'totalReviews': restaurantReviews.length,
      };
    } catch (e) {
      print('❌ Error fetching analytics: $e');
      return {};
    }
  }

  /// Get category breakdown
  static Future<Map<String, int>> getCategoryData() async {
    try {
      // This would require backend analytics endpoint
      // For now, return empty
      return {};
    } catch (e) {
      print('Error fetching category data: $e');
      return {};
    }
  }
}
