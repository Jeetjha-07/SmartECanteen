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
      if (user == null) {
        print('❌ Review: Not logged in');
        return {'success': false, 'error': 'Not logged in'};
      }

      print(
          '📝 Review: Submitting review for orderId: $orderId, rating: $rating');

      final reviewData = {
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
      };

      final response = await ApiService.createReview(reviewData);
      print('✅ Review: Successfully submitted. Response: $response');

      return {'success': true};
    } catch (e) {
      print('❌ Review: Error submitting - $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check if order has been reviewed by current user
  static Future<bool> hasReviewed(String orderId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        print('⚠️ Review: User not logged in - cannot check if reviewed');
        return false;
      }

      final customerId = user.uid;
      print('🔍 Review: Checking if user $customerId reviewed order $orderId');

      final reviews = await getAllReviews();
      print('   Total reviews in system: ${reviews.length}');

      final hasReview = reviews.any((review) =>
          review.orderId == orderId && review.customerId == customerId);

      print('   Result: $hasReview');

      return hasReview;
    } catch (e) {
      print('❌ Review: Error checking review - $e');
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

  // Get reviews for a specific restaurant (AUTHENTICATED - uses JWT token)
  static Future<List<Review>> getRestaurantReviews(String restaurantId) async {
    try {
      print(
          '\n⭐ ReviewService: Fetching reviews for restaurantId: $restaurantId');
      print(
          '   ℹ️ Using authenticated endpoint: GET /reviews/restaurant/my/reviews');

      final response = await ApiService.getRestaurantReviews(restaurantId);

      print('⭐ ReviewService: API returned ${response.length} items');

      if (response.isEmpty) {
        print('⭐ ReviewService: No reviews in response');
        return [];
      }

      print('⭐ ReviewService: Parsing reviews...');
      final reviews = <Review>[];

      for (int i = 0; i < response.length; i++) {
        try {
          print('   📝 Parsing review $i: id=${response[i]['_id']}');
          final review = Review.fromMap(response[i]);
          reviews.add(review);
          print(
              '   ✅ Parsed review: id=${review.id}, rating=${review.rating}, restaurantId=${review.restaurantId}');
        } catch (e) {
          print('   ❌ Error parsing review $i: $e');
          print('      Review ID: ${response[i]['_id'] ?? 'unknown'}');
        }
      }

      print('⭐ ReviewService: Successfully parsed ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      print(
          '❌ ReviewService: Error fetching restaurant reviews for $restaurantId - $e');
      rethrow;
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
    print('\n🔄 ReviewService.getRestaurantReviewsStream: Starting stream');
    print('   restaurantId parameter: $restaurantId');
    if (restaurantId.isEmpty) {
      print(
          '   ⚠️ WARNING: restaurantId is EMPTY! Stream will return empty list');
      // Return a stream that emits empty list periodically
      return Stream.periodic(const Duration(seconds: 5), (_) {
        print('   ⏰ Stream tick: restaurantId is still empty, returning empty');
        return Future.value(<Review>[]);
      }).asyncExpand((future) => future.asStream());
    }

    return Stream.periodic(const Duration(seconds: 5), (_) {
      print(
          '   ⏰ Stream tick: Fetching reviews for restaurantId: $restaurantId');
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
  static Future<Map<int, int>> getRestaurantRatingDistribution(
      String restaurantId) async {
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
