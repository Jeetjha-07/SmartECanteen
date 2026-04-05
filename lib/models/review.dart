class Review {
  final String id;
  final String orderId;
  final String restaurantId;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.orderId,
    required this.restaurantId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    print('🔨 Review.fromMap: Parsing review from: $data');

    final ratingValue = data['rating'] ?? 0;
    final rating = ratingValue is String
        ? double.tryParse(ratingValue) ?? 0.0
        : (ratingValue as num).toDouble();

    final id = data['id'] ?? data['_id'] ?? '';
    final orderId = data['orderId'] ?? '';
    final restaurantId = data['restaurantId'] ?? '';
    final customerId = data['customerId'] ?? '';
    final customerName = data['customerName'] ?? 'Anonymous';
    final comment = data['comment'] ?? '';

    print(
        '🔨 Review.fromMap: Extracted - id=$id, restaurantId=$restaurantId, orderId=$orderId, rating=$rating');

    try {
      final createdAt = data['createdAt'] != null
          ? DateTime.parse(data['createdAt'].toString())
          : DateTime.now();

      return Review(
        id: id,
        orderId: orderId,
        restaurantId: restaurantId,
        customerId: customerId,
        customerName: customerName,
        rating: rating,
        comment: comment,
        createdAt: createdAt,
      );
    } catch (e) {
      print('❌ Review.fromMap: Error creating Review object: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'restaurantId': restaurantId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
