class Restaurant {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String description;
  final String imageUrl;
  final List<String> cuisineTypes;
  final String address;
  final String phone;
  final String city;
  final String zipCode;
  final double averageRating;
  final int totalRatings;
  final bool isOpen;
  final int deliveryTime; // in minutes
  final double deliveryCharge;
  final int minOrderValue;
  final Map<String, dynamic>? operatingHours;
  final int defaultTimeSlotCapacity;
  final int timeSlotDuration;
  final bool isVerified;

  Restaurant({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.description,
    required this.imageUrl,
    required this.cuisineTypes,
    required this.address,
    required this.phone,
    required this.city,
    required this.zipCode,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.isOpen = true,
    this.deliveryTime = 30,
    this.deliveryCharge = 0.0,
    this.minOrderValue = 0,
    this.operatingHours,
    this.defaultTimeSlotCapacity = 20,
    this.timeSlotDuration = 15,
    this.isVerified = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      cuisineTypes: List<String>.from(json['cuisineTypes'] ?? []),
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'] ?? '',
      zipCode: json['zipCode'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      deliveryTime: json['deliveryTime'] ?? 30,
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      minOrderValue: json['minOrderValue'] ?? 0,
      operatingHours: json['operatingHours'],
      defaultTimeSlotCapacity: json['defaultTimeSlotCapacity'] ?? 20,
      timeSlotDuration: json['timeSlotDuration'] ?? 15,
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'description': description,
        'imageUrl': imageUrl,
        'cuisineTypes': cuisineTypes,
        'address': address,
        'phone': phone,
        'city': city,
        'zipCode': zipCode,
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'isOpen': isOpen,
        'deliveryTime': deliveryTime,
        'deliveryCharge': deliveryCharge,
        'minOrderValue': minOrderValue,
        'operatingHours': operatingHours,
        'defaultTimeSlotCapacity': defaultTimeSlotCapacity,
        'timeSlotDuration': timeSlotDuration,
        'isVerified': isVerified,
      };
}
