enum UserRole { customer, restaurant }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? restaurantId;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.restaurantId,
  });

  bool get isRestaurant => role == UserRole.restaurant;
  bool get isCustomer => role == UserRole.customer;

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? data['_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] == 'restaurant'
          ? UserRole.restaurant
          : UserRole.customer,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'].toString())
          : DateTime.now(),
      restaurantId: data['restaurantId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role == UserRole.restaurant ? 'restaurant' : 'customer',
      'createdAt': createdAt.toIso8601String(),
      'restaurantId': restaurantId,
    };
  }
}
