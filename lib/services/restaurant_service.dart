import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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

  // Upload image to backend (which uploads to Cloudinary)
  static Future<String> _uploadImageToCloudinary(XFile imageFile) async {
    try {
      print('📤 Uploading image to Cloudinary via backend...');
      print('   File: ${imageFile.name} (${await imageFile.length()} bytes)');

      // Create multipart request to /restaurants/upload endpoint
      final uri = Uri.parse('${ApiService.baseUrl}/restaurants/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final headers = ApiService.getHeaders();
      request.headers.addAll(headers);

      // Add file
      final bytes = await imageFile.readAsBytes();
      final extension = imageFile.name.split('.').last.toLowerCase();

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
          contentType: http.MediaType('image', extension),
        ),
      );

      // Send request
      print('⏳ Uploading to /restaurants/upload...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('   Response status: ${response.statusCode}');
      print('   Response body: $responseBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final imageUrl = jsonResponse['imageUrl'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          print('   ✅ Image uploaded to Cloudinary: $imageUrl');
          return imageUrl;
        }
      }

      throw 'Upload failed: ${response.statusCode}';
    } catch (e) {
      print('   ❌ Image upload error: $e');
      rethrow;
    }
  }

  // Register shop (with image upload to Cloudinary)
  static Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String description,
    required XFile imageFile,
  }) async {
    try {
      print('📝 Registering shop: $shopName');
      print('📸 Image file: ${imageFile.name}');

      // Step 1: Upload image to Cloudinary
      String cloudinaryUrl = await _uploadImageToCloudinary(imageFile);

      // Step 2: Create request to register endpoint
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/restaurants/register'),
      );

      print('🔗 API Endpoint: ${ApiService.baseUrl}/restaurants/register');

      // Add headers (including Authorization)
      final headers = ApiService.getHeaders();
      request.headers.addAll(headers);

      print('📋 Request Headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('   $key: Bearer [REDACTED]');
        } else {
          print('   $key: $value');
        }
      });

      // Add form fields
      request.fields['restaurantName'] = shopName;
      request.fields['description'] = description;
      request.fields['imageUrl'] = cloudinaryUrl; // Add Cloudinary URL
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

      print('📝 Form Fields:');
      request.fields.forEach((key, value) {
        if (key == 'imageUrl') {
          print('   $key: $value (Cloudinary)');
        } else {
          print('   $key: $value');
        }
      });

      // Send request
      print('⏳ Sending registration request...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response content-type: ${response.headers['content-type']}');
      print('Response body length: ${responseBody.length}');

      // Check if response is HTML (error page) instead of JSON
      if (responseBody.trim().startsWith('<')) {
        print('❌ ERROR: Server returned HTML instead of JSON');
        print('Response preview: ${responseBody.substring(0, 200)}...');
        return {
          'success': false,
          'error':
              'Server error: Invalid response format. Check console logs for details.'
        };
      }

      print('Response body: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(responseBody);
          print('✅ Shop registered successfully');
          return {'success': true, 'restaurant': data['restaurant']};
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('Response was: $responseBody');
          return {
            'success': false,
            'error': 'Invalid response format from server: $e'
          };
        }
      } else {
        try {
          final error = jsonDecode(responseBody);
          print('❌ Error: ${error['error']}');
          return {
            'success': false,
            'error': error['error'] ?? 'Failed to register shop'
          };
        } catch (e) {
          print('❌ JSON Parse Error on error response: $e');
          return {
            'success': false,
            'error':
                'Server error (Status ${response.statusCode}): ${responseBody.substring(0, 100)}'
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error registering shop: $e');
      print('📍 Stack trace: $stackTrace');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
