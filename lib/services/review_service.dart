import '../models/review.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ReviewService {
  // Submit a review via API
  static Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required double rating,
    required String comment,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return {'success': false, 'error': 'Not logged in'};

      final reviewData = {
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
      };
      await ApiService.createReview(reviewData);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check if order has been reviewed by current user
  static Future<bool> hasReviewed(String orderId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      final customerId = user.uid;
      final reviews = await getAllReviews();

      // Check if current user has reviewed this order
      return reviews.any((review) =>
          review.orderId == orderId && review.customerId == customerId);
    } catch (e) {
      print('Error checking review: $e');
      return false;
    }
  }

  // Get all reviews
  static Future<List<Review>> getAllReviews() async {
    try {
      final response = await ApiService.getReviews();
      return response.map((item) => Review.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  // Get reviews for a specific restaurant
  static Future<List<Review>> getRestaurantReviews(String restaurantId) async {
    try {
      final response = await ApiService.getRestaurantReviews(restaurantId);
      return response.map((item) => Review.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching restaurant reviews: $e');
      return [];
    }
  }

  // Stream all reviews (polls every 5 seconds)
  static Stream<List<Review>> getAllReviewsStream() {
    return Stream.periodic(const Duration(seconds: 5), (_) {
      return getAllReviews();
    }).asyncExpand((future) => future.asStream());
  }

  // Stream reviews for a specific restaurant (polls every 5 seconds)
  static Stream<List<Review>> getRestaurantReviewsStream(String restaurantId) {
    return Stream.periodic(const Duration(seconds: 5), (_) {
      return getRestaurantReviews(restaurantId);
    }).asyncExpand((future) => future.asStream());
  }

  // Get average rating
  static Future<double> getAverageRating() async {
    try {
      final reviews = await getAllReviews();
      if (reviews.isEmpty) return 0.0;

      final avg =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      return avg;
    } catch (e) {
      print('Error calculating average rating: $e');
      return 0.0;
    }
  }

  // Get average rating for a restaurant
  static Future<double> getRestaurantAverageRating(String restaurantId) async {
    try {
      final reviews = await getRestaurantReviews(restaurantId);
      if (reviews.isEmpty) return 0.0;

      final avg =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
      return avg;
    } catch (e) {
      print('Error calculating restaurant average rating: $e');
      return 0.0;
    }
  }

  // Get rating distribution (1-5 stars count)
  static Future<Map<int, int>> getRatingDistribution() async {
    try {
      final reviews = await getAllReviews();
      final Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final review in reviews) {
        final star = review.rating.round();
        distribution[star] = (distribution[star] ?? 0) + 1;
      }
      return distribution;
    } catch (e) {
      print('Error getting rating distribution: $e');
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
  }

  // Get rating distribution for a restaurant
  static Future<Map<int, int>> getRestaurantRatingDistribution(String restaurantId) async {
    try {
      final reviews = await getRestaurantReviews(restaurantId);
      final Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final review in reviews) {
        final star = review.rating.round();
        distribution[star] = (distribution[star] ?? 0) + 1;
      }
      return distribution;
    } catch (e) {
      print('Error getting restaurant rating distribution: $e');
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
  }
}
