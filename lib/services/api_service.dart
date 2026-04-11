import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Static JWT token storage
  static String? _jwtToken;

  // 🎯 Local development backend
  static const String baseUrl = 'http://localhost:3000/api';

  // Base server URL for accessing static files (uploads, etc)
  // Remove /api from the end to get the server root
  static String get serverBaseUrl {
    return baseUrl.replaceAll('/api', '');
  }

  // Production backend on Render (switch back when ready for deployment)
  // static const String baseUrl = 'https://smartecanteen-1.onrender.com/api';

  /// Set JWT token (called after login/register)
  static void setToken(String token) {
    _jwtToken = token;
    print('🔐 JWT token set');
  }

  /// Clear JWT token (called on logout)
  static void clearToken() {
    _jwtToken = null;
    print('🔐 JWT token cleared');
  }

  /// Get headers with JWT token
  static Map<String, String> getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_jwtToken != null && _jwtToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  // Make HTTP requests with error handling
  static Future<dynamic> _makeRequest(
    String method,
    String url, {
    dynamic body,
  }) async {
    try {
      final headers = getHeaders();
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
        final errorMsg =
            'API Error: ${response.statusCode}\nURL: $url\nResponse: ${response.body}';
        print('❌ $errorMsg');
        throw Exception(errorMsg);
      }
    } on SocketException catch (e) {
      final error =
          '❌ Connection Error: Cannot connect to server\nMake sure backend is running!\nError: $e';
      print(error);
      throw Exception(error);
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }
  }

  // Generic instance methods for services to use
  Future<dynamic> get(String url) async {
    return await _makeRequest('GET', url);
  }

  Future<dynamic> post(String url, {dynamic body}) async {
    return await _makeRequest('POST', url, body: body);
  }

  Future<dynamic> put(String url, {dynamic body}) async {
    return await _makeRequest('PUT', url, body: body);
  }

  Future<dynamic> delete(String url) async {
    return await _makeRequest('DELETE', url);
  }

  // Public static method for services to call (wrapper for _makeRequest)
  static Future<dynamic> makeRequest(
    String method,
    String url, {
    dynamic body,
  }) async {
    return await _makeRequest(method, url, body: body);
  }

  // AUTH ENDPOINTS
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    return await _makeRequest('POST', '$baseUrl/users/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _makeRequest('POST', '$baseUrl/users/login', body: {
      'email': email,
      'password': password,
    });
  }

  // USER ENDPOINTS
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
      {String? category, String? restaurantId}) async {
    String url = '$baseUrl/menu';
    final params = <String>[];
    if (category != null) params.add('category=$category');
    if (restaurantId != null) params.add('restaurantId=$restaurantId');
    if (params.isNotEmpty) url += '?${params.join('&')}';

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

  static Future<List<Map<String, dynamic>>> getRestaurantReviews(
      String restaurantId) async {
    // Use authenticated endpoint for restaurant app
    final url = '$baseUrl/reviews/restaurant/my/reviews';
    print('\n🔍 API: Fetching restaurant reviews (AUTHENTICATED)');
    print('   URL: $url');
    print('   restaurantId param (unused): $restaurantId');

    try {
      final result = await _makeRequest('GET', url);

      print('🔍 API: Response type: ${result.runtimeType}');
      print('🔍 API: Response data: $result');

      if (result is List) {
        print('🔍 API: Response is a List with ${result.length} items');
        final reviews = List<Map<String, dynamic>>.from(result);
        print('🔍 API: Converted to ${reviews.length} review maps');
        if (reviews.isNotEmpty) {
          print('🔍 API: First review: ${reviews[0]}');
        }
        return reviews;
      } else if (result is Map) {
        print('❌ API: Response is a Map, not a List! Response: $result');
        return [];
      } else {
        print('❌ API: Unknown response type: ${result.runtimeType}');
        return [];
      }
    } catch (e) {
      print('❌ API: Error fetching restaurant reviews: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateReview(
      String id, Map<String, dynamic> reviewData) async {
    return await _makeRequest('PUT', '$baseUrl/reviews/$id', body: reviewData);
  }

  static Future<void> deleteReview(String id) async {
    await _makeRequest('DELETE', '$baseUrl/reviews/$id');
  }
}
