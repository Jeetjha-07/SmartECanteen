import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
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
        url += '?' + params.join('&');
      }
      
      print('🔍 Fetching menu items from: $url');

      final response = await _apiService.get(url);

      if (response != null) {
        final List<dynamic> data =
            response is String ? jsonDecode(response) : response;
        items = (data)
            .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
            .toList();
        print('✅ Loaded ${items.length} menu items for restaurant: $restaurantId');
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
      {File? imageFile}) async {
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
      return result;
    } catch (e) {
      print('❌ Error adding menu item: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update menu item
  static Future<bool> updateMenuItem(FoodItem item, {File? imageFile}) async {
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
  static Future<bool> toggleAvailability(
      String itemId, bool isAvailable) async {
    try {
      print('🔄 Toggling availability for item $itemId to: $isAvailable');
      final result =
          await ApiService.toggleMenuItemAvailability(itemId, isAvailable);
      print(
          '✅ Availability toggled: ${result['name']} is now ${isAvailable ? 'Available' : 'Out of Stock'}');
      return true;
    } catch (e) {
      print('❌ Error toggling availability: $e');
      return false;
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

  // Upload image - you can use Cloudinary, AWS S3, or your preferred service
  static Future<String> _uploadImage(File imageFile) async {
    // TODO: Implement image upload to Cloudinary or other service
    // For now, returning a placeholder
    return 'https://via.placeholder.com/400';
  }
}
