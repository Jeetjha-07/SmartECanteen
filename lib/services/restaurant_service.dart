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
      print('✅ Got Cloudinary URL: $cloudinaryUrl');

      // Step 2: Send JSON registration data to backend
      final registrationData = {
        'restaurantName': shopName,
        'description': description,
        'imageUrl': cloudinaryUrl, // Cloudinary URL from Step 1
        'cuisineTypes': 'Multi-Cuisine',
        'address': 'To be updated',
        'phone': 'To be updated',
        'city': 'Bangalore',
        'zipCode': '560000',
        'deliveryTime': 30,
        'deliveryCharge': 50,
        'minOrderValue': 100,
        'defaultTimeSlotCapacity': 20,
        'isVerified': true,
        'isOpen': true,
      };

      print('🔗 API Endpoint: ${ApiService.baseUrl}/restaurants/register');
      print('📋 Registration Data:');
      registrationData.forEach((key, value) {
        if (key == 'imageUrl') {
          print('   $key: $value (Cloudinary)');
        } else {
          print('   $key: $value');
        }
      });

      // Step 3: Send JSON POST request
      print('⏳ Sending registration request...');
      final headers = ApiService.getHeaders();

      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/restaurants/register'),
            headers: headers,
            body: jsonEncode(registrationData),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ Shop registered successfully');
          return {'success': true, 'restaurant': data['restaurant']};
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          return {
            'success': false,
            'error': 'Invalid response format from server: $e'
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
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
                'Server error (Status ${response.statusCode}): ${response.body.substring(0, 100)}'
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
