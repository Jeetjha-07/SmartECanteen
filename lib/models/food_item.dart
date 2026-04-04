class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String restaurantId;
  final bool isAvailable;
  final DateTime? createdAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurantId,
    this.isAvailable = true,
    this.createdAt,
  });

  factory FoodItem.fromMap(Map<String, dynamic> data) {
    return FoodItem(
      id: data['id'] ?? data['_id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
      'category': category,
      'isAvailable': isAvailable,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? restaurantId,
    bool? isAvailable,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      restaurantId: restaurantId ?? this.restaurantId,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
    );
  }
}
