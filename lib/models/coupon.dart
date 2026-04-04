class Coupon {
  final String id;
  final String code;
  final String restaurantId;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final int minOrderValue;
  final double? maxDiscount;
  final int? maxUses;
  final int usesPerUser;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final int usedCount;

  Coupon({
    required this.id,
    required this.code,
    required this.restaurantId,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue = 0,
    this.maxDiscount,
    this.maxUses,
    this.usesPerUser = 1,
    required this.validFrom,
    required this.validUntil,
    this.isActive = true,
    this.usedCount = 0,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderValue: json['minOrderValue'] ?? 0,
      maxDiscount:
          json['maxDiscount'] != null ? (json['maxDiscount']).toDouble() : null,
      maxUses: json['maxUses'],
      usesPerUser: json['usesPerUser'] ?? 1,
      validFrom: DateTime.parse(json['validFrom'] ?? DateTime.now().toString()),
      validUntil:
          DateTime.parse(json['validUntil'] ?? DateTime.now().toString()),
      isActive: json['isActive'] ?? true,
      usedCount: json['usedCount'] ?? 0,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  bool get isExpired {
    return DateTime.now().isAfter(validUntil);
  }

  String get displayDiscount {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    } else {
      return '₹${discountValue.toStringAsFixed(0)} OFF';
    }
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        'restaurantId': restaurantId,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
        'maxDiscount': maxDiscount,
        'maxUses': maxUses,
        'usesPerUser': usesPerUser,
        'validFrom': validFrom.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'isActive': isActive,
        'usedCount': usedCount,
      };
}
