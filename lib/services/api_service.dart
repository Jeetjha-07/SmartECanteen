import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // 🎯 Automatically detect platform and use correct URL
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web: Use localhost (running in browser)
      return 'http://localhost:3000/api';
    } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Mobile: Detect automatically
      if (Platform.isAndroid) {
        // Android emulator special IP
        return 'http://10.0.2.2:3000/api';
      } else {
        // iOS simulator
        return 'http://localhost:3000/api';
      }
    } else {
      // Windows/Mac desktop
      return 'http://localhost:3000/api';
    }
  }
  
  // For production deployment
  static const String productionUrl = 'https://your-domain.com/api';

  static Future<String?> getAuthToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get headers with Firebase token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Make HTTP requests with error handling
  static Future<dynamic> _makeRequest(
    String method,
    String url, {
    dynamic body,
  }) async {
    try {
      final headers = await getHeaders();
      late http.Response response;
      
      print('📡 API Request: $method $url');
      if (body != null) print('   Body: ${jsonEncode(body)}');

      switch (method) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(Uri.parse(url),
              headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(Uri.parse(url),
              headers: headers, body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(Uri.parse(url),
              headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
      }

      print('📡 Response Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorMsg = 'API Error: ${response.statusCode}\nURL: $url\nResponse: ${response.body}';
        print('❌ $errorMsg');
        throw Exception(errorMsg);
      }
    } on SocketException catch (e) {
      final error = '❌ Connection Error: Cannot connect to server at ${url.split('/api')[0]}\nMake sure backend is running!\nError: $e';
      print(error);
      throw Exception(error);
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }
  }

  // USER ENDPOINTS
  static Future<Map<String, dynamic>> syncUser(
      {required String name, required String role}) async {
    return await _makeRequest('POST', '$baseUrl/users/sync',
        body: {'name': name, 'role': role});
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    return await _makeRequest('GET', '$baseUrl/users/me');
  }

  static Future<Map<String, dynamic>> updateUser({
    String? name,
    String? phoneNumber,
    String? address,
    String? profileImage,
  }) async {
    return await _makeRequest('PUT', '$baseUrl/users/me', body: {
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      if (profileImage != null) 'profileImage': profileImage,
    });
  }

  // MENU ENDPOINTS
  static Future<List<Map<String, dynamic>>> getMenuItems(
      {String? category}) async {
    String url = '$baseUrl/menu';
    if (category != null) {
      url += '?category=$category';
    }
    final result = await _makeRequest('GET', url);
    return List<Map<String, dynamic>>.from(result);
  }

  // Get ALL menu items including unavailable (for restaurant admin)
  static Future<List<Map<String, dynamic>>> getAllMenuItems(
      {String? category}) async {
    String url = '$baseUrl/menu/all/items';
    if (category != null) {
      url += '?category=$category';
    }
    final result = await _makeRequest('GET', url);
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<Map<String, dynamic>> getMenuItem(String id) async {
    return await _makeRequest('GET', '$baseUrl/menu/$id');
  }

  static Future<Map<String, dynamic>> createMenuItem(
      Map<String, dynamic> itemData) async {
    return await _makeRequest('POST', '$baseUrl/menu', body: itemData);
  }

  static Future<Map<String, dynamic>> updateMenuItem(
      String id, Map<String, dynamic> itemData) async {
    return await _makeRequest('PUT', '$baseUrl/menu/$id', body: itemData);
  }

  static Future<void> deleteMenuItem(String id) async {
    await _makeRequest('DELETE', '$baseUrl/menu/$id');
  }

  static Future<Map<String, dynamic>> toggleMenuItemAvailability(
      String id, bool isAvailable) async {
    return await _makeRequest('PATCH', '$baseUrl/menu/$id/availability',
        body: {'isAvailable': isAvailable});
  }

  // ORDER ENDPOINTS
  static Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    return await _makeRequest('POST', '$baseUrl/orders', body: orderData);
  }

  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    final result = await _makeRequest('GET', '$baseUrl/orders');
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    final result = await _makeRequest('GET', '$baseUrl/orders/all/orders');
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<Map<String, dynamic>> getOrder(String id) async {
    return await _makeRequest('GET', '$baseUrl/orders/$id');
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
      String id, String status) async {
    return await _makeRequest('PATCH', '$baseUrl/orders/$id/status',
        body: {'status': status});
  }

  static Future<Map<String, dynamic>> cancelOrder(String id) async {
    return await _makeRequest('PATCH', '$baseUrl/orders/$id/cancel');
  }

  static Future<Map<String, dynamic>> deleteOrder(String id) async {
    return await _makeRequest('DELETE', '$baseUrl/orders/$id');
  }

  // REVIEW ENDPOINTS
  static Future<Map<String, dynamic>> createReview(
      Map<String, dynamic> reviewData) async {
    return await _makeRequest('POST', '$baseUrl/reviews', body: reviewData);
  }

  static Future<List<Map<String, dynamic>>> getReviews(
      {String? orderId}) async {
    String url = '$baseUrl/reviews';
    if (orderId != null) {
      url = '$baseUrl/reviews/order/$orderId';
    }
    final result = await _makeRequest('GET', url);
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<Map<String, dynamic>> updateReview(
      String id, Map<String, dynamic> reviewData) async {
    return await _makeRequest('PUT', '$baseUrl/reviews/$id', body: reviewData);
  }

  static Future<void> deleteReview(String id) async {
    await _makeRequest('DELETE', '$baseUrl/reviews/$id');
  }
}
