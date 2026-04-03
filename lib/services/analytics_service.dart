import 'order_service.dart';
import 'review_service.dart';

class AnalyticsService {
  /// Get basic analytics
  static Future<Map<String, dynamic>> getBasicAnalytics() async {
    try {
      // Gather data from available services
      final allOrders = await OrderService.getAllOrders();
      final avgRating = await ReviewService.getAverageRating();
      final ratingDist = await ReviewService.getRatingDistribution();

      // Calculate quick stats
      final totalRevenue = allOrders
          .where((o) => o.status == 'Delivered')
          .fold(0.0, (sum, o) => sum + o.totalAmount);

      final deliveredCount =
          allOrders.where((o) => o.status == 'Delivered').length;
      final pendingCount = allOrders.where((o) => o.status == 'Pending').length;
      final cancelledCount =
          allOrders.where((o) => o.status == 'Cancelled').length;

      return {
        'totalOrders': allOrders.length,
        'totalRevenue': totalRevenue,
        'deliveredOrders': deliveredCount,
        'pendingOrders': pendingCount,
        'cancelledOrders': cancelledCount,
        'cancelRate': allOrders.isNotEmpty
            ? (cancelledCount / allOrders.length * 100).toStringAsFixed(1)
            : '0',
        'avgRating': avgRating,
        'ratingDistribution': ratingDist,
      };
    } catch (e) {
      print('Error fetching analytics: $e');
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
