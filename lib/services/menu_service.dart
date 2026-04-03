import 'dart:io';
import '../models/food_item.dart';
import 'api_service.dart';

class MenuService {
  // Get all available menu items (for customers)
  static Future<List<FoodItem>> getMenuItems({String? category}) async {
    try {
      final data = await ApiService.getMenuItems(category: category);
      return data.map((item) => FoodItem.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      return [];
    }
  }

  // Get ALL menu items including unavailable (for restaurant admin)
  static Future<List<FoodItem>> getAllMenuItems({String? category}) async {
    try {
      print('📋 Fetching ALL menu items (including unavailable)...');
      final data = await ApiService.getAllMenuItems(category: category);
      print('✅ Got ${data.length} items (available + unavailable)');
      return data.map((item) => FoodItem.fromMap(item)).toList();
    } catch (e) {
      print('❌ Error fetching all menu items: $e');
      return [];
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
      final result = await ApiService.toggleMenuItemAvailability(itemId, isAvailable);
      print('✅ Availability toggled: ${result['name']} is now ${isAvailable ? 'Available' : 'Out of Stock'}');
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
