import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../services/review_service.dart';
import '../../models/review.dart';
import '../../utils/app_colors.dart';

class RestaurantReviewsScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantReviewsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<RestaurantReviewsScreen> createState() =>
      _RestaurantReviewsScreenState();
}

class _RestaurantReviewsScreenState extends State<RestaurantReviewsScreen> {
  Future<void> _refreshReviews() async {
    print(
        '\n🔄 RestaurantReviewsScreen: Refreshing reviews for: ${widget.restaurantId}');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    print('\n🎬 RestaurantReviewsScreen State initState:');
    print('   restaurantId: ${widget.restaurantId}');
    if (widget.restaurantId.isEmpty) {
      print('   ⚠️ WARNING: restaurantId is EMPTY!');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('\n🔵 RestaurantReviewsScreen: Build called');
    print('   restaurantId from widget: ${widget.restaurantId}');
    print('   restaurantId isEmpty: ${widget.restaurantId.isEmpty}');
    return RefreshIndicator(
      onRefresh: _refreshReviews,
      color: AppColors.primaryOrange,
      child: StreamBuilder<List<Review>>(
        stream: ReviewService.getRestaurantReviewsStream(widget.restaurantId),
        builder: (context, snapshot) {
          print(
              '\n📡 StreamBuilder: Connection state: ${snapshot.connectionState}');
          print(
              '   hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
          if (snapshot.hasData) {
            print('   Data count: ${snapshot.data?.length ?? 0}');
          }
          if (snapshot.hasError) {
            print('   Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No reviews yet',
                        style:
                            TextStyle(fontSize: 18, color: AppColors.textGrey)),
                    SizedBox(height: 6),
                    Text('Reviews from customers will appear here',
                        style: TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ),
            );
          }

          // Compute stats
          final avgRating =
              reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;
          final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (final r in reviews) {
            dist[r.rating.round()] = (dist[r.rating.round()] ?? 0) + 1;
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating Summary Card
                _RatingSummaryCard(
                    avgRating: avgRating,
                    totalReviews: reviews.length,
                    distribution: dist),
                const SizedBox(height: 20),

                // Reviews header
                Row(
                  children: [
                    const Text('All Reviews',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${reviews.length} total',
                        style: const TextStyle(color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 10),

                // Reviews list
                ...reviews.map((r) => _ReviewCard(review: r)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  final double avgRating;
  final int totalReviews;
  final Map<int, int> distribution;

  const _RatingSummaryCard({
    required this.avgRating,
    required this.totalReviews,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left - Big Rating
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              RatingBarIndicator(
                rating: avgRating,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 18,
              ),
              const SizedBox(height: 4),
              Text('$totalReviews reviews',
                  style:
                      const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 20),
          // Right - Distribution bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final pct = totalReviews > 0 ? count / totalReviews : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('$star',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textGrey)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.amber),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textGrey)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryOrange,
                radius: 18,
                child: Text(
                  review.customerName.isNotEmpty
                      ? review.customerName[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(dateFormat.format(review.createdAt),
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 11)),
                  ],
                ),
              ),
              RatingBarIndicator(
                rating: review.rating,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 16,
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${review.comment}"',
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textDark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
