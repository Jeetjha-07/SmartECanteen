import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import 'api_service.dart';

class MenuService extends ChangeNotifier {
  List<FoodItem> items = [];
  bool isLoading = false;
  String? error;

  final ApiService _apiService = ApiService();

  // Get menu items for a specific restaurant
  Future<void> getMenuItems({String? restaurantId, String? category}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      String url = '${ApiService.baseUrl}/menu';

      // Build query parameters
      List<String> params = [];
      if (restaurantId != null && restaurantId.isNotEmpty) {
        params.add('restaurantId=$restaurantId');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=$category');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      print('🔍 Fetching menu items from: $url');

      final response = await _apiService.get(url);

      if (response != null) {
        final List<dynamic> data =
            response is String ? jsonDecode(response) : response;
        items = (data)
            .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
            .toList();
        print(
            '✅ Loaded ${items.length} menu items for restaurant: $restaurantId');
        for (var item in items) {
          print('   📌 Item: ${item.name}, ImageURL: ${item.imageUrl}');
        }
      } else {
        print('⚠️ No response from menu API');
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching menu items: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get ALL menu items including unavailable (for restaurant admin)
  // Returns empty list if shop not registered, but doesn't store error
  static Future<List<FoodItem>> getAllMenuItems({String? category}) async {
    try {
      print('📋 Fetching ALL menu items (including unavailable)...');
      final data = await ApiService.getAllMenuItems(category: category);
      print('✅ Got ${data.length} items (available + unavailable)');
      return data.map((item) => FoodItem.fromMap(item)).toList();
    } catch (e) {
      final errorStr = e.toString();
      // Check if it's a shop registration error
      if (errorStr.contains('Shop must be registered')) {
        print('🔒 Menu is locked: Shop not registered');
      } else {
        print('❌ Error fetching all menu items: $e');
      }
      return [];
    }
  }

  // Check if menu is locked due to shop not being registered
  static Future<bool> isMenuLocked() async {
    try {
      await ApiService.getAllMenuItems();
      return false; // Menu is not locked if we can fetch items
    } catch (e) {
      final errorStr = e.toString();
      // Menu is locked if we get the specific shop registration error
      return errorStr.contains('Shop must be registered');
    }
  }

  // Get single menu item
  static Future<FoodItem?> getMenuItem(String id) async {
    try {
      final data = await ApiService.getMenuItem(id);
      return FoodItem.fromMap(data);
    } catch (e) {
      print('Error fetching menu item: $e');
      return null;
    }
  }

  // Add new menu item
  static Future<Map<String, dynamic>> addMenuItem(FoodItem item,
      {XFile? imageFile}) async {
    try {
      String imageUrl = item.imageUrl;

      print('📝 Adding menu item: ${item.name}');
      print('   Image URL provided: $imageUrl');

      // Only upload if a file is provided
      if (imageFile != null) {
        print('   Uploading image file...');
        imageUrl = await _uploadImage(imageFile);
        print('   Image uploaded to: $imageUrl');
      } else if (imageUrl.isEmpty) {
        // If no URL and no file, don't include image
        imageUrl = '';
      }

      final itemData = item.toMap();
      itemData['imageUrl'] = imageUrl;

      print('   Sending to backend with URL: $imageUrl');
      final result = await ApiService.createMenuItem(itemData);
      print('✅ Menu item added: ${result['item']?['_id'] ?? 'Unknown'}');
      print(
          '   Stored imageUrl in DB: ${result['item']?['imageUrl'] ?? 'NOT SET'}');
      return result;
    } catch (e) {
      print('❌ Error adding menu item: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update menu item
  static Future<bool> updateMenuItem(FoodItem item, {XFile? imageFile}) async {
    try {
      String imageUrl = item.imageUrl;

      print('📝 Updating menu item: ${item.name}');
      print('   Current Image URL: $imageUrl');

      if (imageFile != null) {
        print('   Uploading new image file...');
        imageUrl = await _uploadImage(imageFile);
        print('   Image uploaded to: $imageUrl');
      }

      final itemData = item.toMap();
      itemData['imageUrl'] = imageUrl;

      print('   Sending to backend with URL: $imageUrl');
      await ApiService.updateMenuItem(item.id, itemData);
      print('✅ Menu item updated: ${item.id}');
      return true;
    } catch (e) {
      print('❌ Error updating menu item: $e');
      return false;
    }
  }

  // Toggle item availability
  static Future<Map<String, dynamic>> toggleAvailability(
      String itemId, bool isAvailable) async {
    try {
      print('🔄 Toggling availability for item $itemId to: $isAvailable');
      final result =
          await ApiService.toggleMenuItemAvailability(itemId, isAvailable);
      print(
          '✅ Availability toggled: ${result['name']} is now ${isAvailable ? 'Available' : 'Out of Stock'}');
      return {'success': true, 'data': result};
    } catch (e) {
      print('❌ Error toggling availability: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete menu item
  static Future<bool> deleteMenuItem(String itemId) async {
    try {
      await ApiService.deleteMenuItem(itemId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Upload image to backend
  static Future<String> _uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;

      // Get file extension
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      print('   📤 Uploading file: $fileName (${bytes.length} bytes)');
      print('   Extension: .$extension, MIME: $mimeType');

      // Create multipart request to /menu/upload endpoint
      final uri = Uri.parse('${ApiService.baseUrl}/menu/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer ${ApiService.getAuthToken()}';
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: http.MediaType(
            mimeType.split('/')[0],
            mimeType.split('/')[1],
          ),
        ),
      );

      print('   Sending request to: ${uri.path}');

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('   Response status: ${response.statusCode}');
      print('   Response body: $responseBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final imageUrl = jsonResponse['imageUrl'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          print('   ✅ Upload successful: $imageUrl');
          return imageUrl;
        }
      }

      throw 'Upload failed: ${response.statusCode}';
    } catch (e) {
      print('   ❌ Image upload error: $e');
      rethrow;
    }
  }

  // Get MIME type from file extension
  static String _getMimeType(String extension) {
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
    };
    return mimeTypes[extension] ?? 'image/jpeg';
  }
}
