class TimeSlot {
  final String id;
  final String restaurantId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int capacity;
  final int currentOrders;
  final bool isAvailable;

  TimeSlot({
    required this.id,
    required this.restaurantId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.currentOrders = 0,
    this.isAvailable = true,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['_id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      capacity: json['capacity'] ?? 20,
      currentOrders: json['currentOrders'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  bool get isFull => currentOrders >= capacity;

  String get displayTime => '$startTime - $endTime';

  Map<String, dynamic> toJson() => {
        '_id': id,
        'restaurantId': restaurantId,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
        'currentOrders': currentOrders,
        'isAvailable': isAvailable,
      };
}
