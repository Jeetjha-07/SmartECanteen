import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/restaurant.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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

  // Register shop (with image file upload)
  static Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String description,
    required File imageFile,
  }) async {
    try {
      print('📝 Registering shop: $shopName');
      print('📸 Image file: ${imageFile.path}');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/restaurants/register'),
      );

      // Add headers (including Authorization)
      final headers = ApiService.getHeaders();
      request.headers.addAll(headers);

      // Add form fields
      request.fields['restaurantName'] = shopName;
      request.fields['description'] = description;
      request.fields['cuisineTypes'] = 'Multi-Cuisine';
      request.fields['address'] = 'To be updated';
      request.fields['phone'] = 'To be updated';
      request.fields['city'] = 'Bangalore';
      request.fields['zipCode'] = '560000';
      request.fields['deliveryTime'] = '30';
      request.fields['deliveryCharge'] = '50';
      request.fields['minOrderValue'] = '100';
      request.fields['defaultTimeSlotCapacity'] = '20';
      request.fields['isVerified'] = 'true';
      request.fields['isOpen'] = 'true';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        print('✅ Shop registered successfully');
        return {'success': true, 'restaurant': data['restaurant']};
      } else {
        final error = jsonDecode(responseBody);
        print('❌ Error: ${error['error']}');
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to register shop'
        };
      }
    } catch (e) {
      print('❌ Error registering shop: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
