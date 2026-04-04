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
    final ratingValue = data['rating'] ?? 0;
    final rating = ratingValue is String ? double.tryParse(ratingValue) ?? 0.0 : (ratingValue as num).toDouble();
    
    return Review(
      id: data['id'] ?? data['_id'] ?? '',
      orderId: data['orderId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Anonymous',
      rating: rating,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'].toString())
          : DateTime.now(),
    );
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
