import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/time_slot.dart';
import 'dart:convert';

class TimeSlotService extends ChangeNotifier {
  List<TimeSlot> timeSlots = [];
  Map<String, dynamic>? slotStats;
  bool isLoading = false;
  String? error;

  final ApiService _apiService = ApiService();

  // Get available time slots for a restaurant on a specific date
  Future<void> getAvailableSlots(String restaurantId, DateTime date) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiService.get(
        '${ApiService.baseUrl}/timeslots/available/$restaurantId/$dateStr',
      );

      if (response != null) {
        final List<dynamic> data =
            response is String ? jsonDecode(response) : response;
        timeSlots = (data)
            .map((item) => TimeSlot.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching time slots: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Generate time slots for a day with custom times and capacity
  Future<bool> generateSlots(
    DateTime date, {
    String? startTime,
    String? endTime,
    int? capacity,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final body = {
        'date': dateStr,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (capacity != null) 'capacity': capacity,
      };

      print('🔄 Generating time slots: $body');
      final response = await _apiService.post(
        '${ApiService.baseUrl}/timeslots/generate',
        body: body,
      );

      if (response != null) {
        print('✅ Time slots generated successfully');
        await getMyTimeSlots(date: date); // Reload slots
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('❌ Error generating time slots: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get all time slots for restaurant (with optional date filter)
  Future<void> getMyTimeSlots({DateTime? date}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      String url = '${ApiService.baseUrl}/timeslots/owner/slots';
      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '?date=$dateStr';
      }

      final response = await _apiService.get(url);

      if (response != null) {
        final List<dynamic> data =
            response is String ? jsonDecode(response) : response;
        timeSlots = (data)
            .map((item) => TimeSlot.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching my time slots: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update time slot capacity
  Future<bool> updateSlotCapacity(String slotId, int capacity) async {
    try {
      final response = await _apiService.put(
        '${ApiService.baseUrl}/timeslots/$slotId',
        body: {'capacity': capacity},
      );

      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error updating slot capacity: $e');
      return false;
    }
  }

  // Toggle slot availability
  Future<bool> toggleSlotAvailability(String slotId, bool isAvailable) async {
    try {
      final response = await _apiService.put(
        '${ApiService.baseUrl}/timeslots/$slotId',
        body: {'isAvailable': isAvailable},
      );

      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error toggling slot availability: $e');
      return false;
    }
  }

  // Get slot statistics for a day
  Future<void> getSlotStats(DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiService.get(
        '${ApiService.baseUrl}/timeslots/owner/stats/$dateStr',
      );

      if (response != null) {
        slotStats = response is String ? jsonDecode(response) : response;
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching slot stats: $e');
    }
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
