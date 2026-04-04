import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/restaurant.dart';
import 'dart:convert';

class RestaurantService extends ChangeNotifier {
  List<Restaurant> restaurants = [];
  Restaurant? selectedRestaurant;
  bool isLoading = false;
  String? error;

  final ApiService _apiService = ApiService();

  // Get all restaurants with filters
  Future<void> getRestaurants({
    String? city,
    String? cuisine,
    String? search,
    String? sortBy,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      String url = '${ApiService.baseUrl}/restaurants/all?';

      if (city != null) url += 'city=$city&';
      if (cuisine != null) url += 'cuisine=$cuisine&';
      if (search != null) url += 'search=$search&';
      if (sortBy != null) url += 'sortBy=$sortBy&';

      final response = await _apiService.get(url);

      if (response != null) {
        final List<dynamic> data =
            response is String ? jsonDecode(response) : response;
        restaurants = (data)
            .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching restaurants: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get restaurant by ID
  Future<Restaurant?> getRestaurantById(String restaurantId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '${ApiService.baseUrl}/restaurants/$restaurantId',
      );

      if (response != null) {
        selectedRestaurant = Restaurant.fromJson(
          response is String ? jsonDecode(response) : response,
        );
        return selectedRestaurant;
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching restaurant: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Register new restaurant
  Future<bool> registerRestaurant(Map<String, dynamic> restaurantData) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiService.baseUrl}/restaurants/register',
        body: restaurantData,
      );

      if (response != null) {
        selectedRestaurant = Restaurant.fromJson(
          response is String ? jsonDecode(response) : response['restaurant'],
        );
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error registering restaurant: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update restaurant details
  Future<bool> updateRestaurant(Map<String, dynamic> updates) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '${ApiService.baseUrl}/restaurants/owner/update',
        body: updates,
      );

      if (response != null) {
        selectedRestaurant = Restaurant.fromJson(
          response is String
              ? jsonDecode(response)['restaurant']
              : response['restaurant'],
        );
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error updating restaurant: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update time slot capacity
  Future<bool> updateTimeSlotSettings({
    required int capacity,
    required int duration,
  }) async {
    try {
      final response = await _apiService.put(
        '${ApiService.baseUrl}/restaurants/owner/timeslot-capacity',
        body: {
          'defaultTimeSlotCapacity': capacity,
          'timeSlotDuration': duration,
        },
      );

      if (response != null) {
        selectedRestaurant = Restaurant.fromJson(
          response is String
              ? jsonDecode(response)['restaurant']
              : response['restaurant'],
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error updating time slot settings: $e');
      return false;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  // Register shop (simple form: name, description, image)
  static Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String description,
    required String imageUrl,
  }) async {
    try {
      print('📝 Registering shop: $shopName');

      final response = await ApiService.makeRequest(
        'POST',
        '${ApiService.baseUrl}/restaurants/register',
        body: {
          'restaurantName': shopName,
          'description': description,
          'imageUrl': imageUrl,
          'cuisineTypes': ['Multi-Cuisine'],
          'address': 'To be updated',
          'phone': 'To be updated',
          'city': 'Bangalore',
          'zipCode': '560000',
          'deliveryTime': 30,
          'deliveryCharge': 50,
          'minOrderValue': 100,
          'defaultTimeSlotCapacity': 20,
          'isVerified': true, // Show in customer list
          'isOpen': true, // Make shop open
        },
      );

      if (response != null) {
        print('✅ Shop registered successfully');
        return {'success': true, 'restaurant': response['restaurant']};
      }
      return {'success': false, 'error': 'Failed to register shop'};
    } catch (e) {
      print('❌ Error registering shop: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
