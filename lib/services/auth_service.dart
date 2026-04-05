import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'jwt_token';
  static const storage = FlutterSecureStorage();

  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
  static String get userName => _currentUser?.name ?? '';
  static String get userEmail => _currentUser?.email ?? '';
  static bool get isRestaurant => _currentUser?.isRestaurant ?? false;

  // Stream controller for auth state changes
  static final _authStateController = StreamController<AppUser?>.broadcast();
  static Stream<AppUser?> get authStateChanges =>
      _authStateController.stream;

  // Initialize auth - load saved token and user
  static Future<void> initializeAuth() async {
    try {
      final token = await storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        // Token exists, set it for API calls
        ApiService.setToken(token);
        // Load current user
        final user = await getCurrentUserFromApi();
        if (user != null) {
          _currentUser = user;
          _authStateController.add(_currentUser);
        }
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
    }
  }

  // Load user data from MongoDB backend
  static Future<AppUser?> getCurrentUserFromApi() async {
    try {
      final userData = await ApiService.getCurrentUser();
      _currentUser = AppUser.fromMap(userData);
      return _currentUser;
    } catch (e) {
      print('❌ Error loading user: $e');
      return null;
    }
  }

  // Register new user with email/password
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    try {
      print('📝 Registering user: $email');

      // Call backend register endpoint
      final result = await ApiService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      if (result['success'] == true && result['token'] != null) {
        // Save JWT token to secure storage
        final token = result['token'];
        await storage.write(key: _tokenKey, value: token);

        // Set token for API service
        ApiService.setToken(token);

        // Parse user data
        _currentUser = AppUser.fromMap(result['user']);

        _authStateController.add(_currentUser);
        print('✅ User registered successfully');
        return {'success': true, 'user': _currentUser};
      } else {
        final error = result['error'] ?? 'Registration failed';
        print('❌ Registration error: $error');
        return {'success': false, 'error': error};
      }
    } catch (e) {
      print('❌ Unexpected error during registration: $e');
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Login with email/password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Logging in user: $email');

      // Call backend login endpoint
      final result = await ApiService.login(
        email: email,
        password: password,
      );

      if (result['success'] == true && result['token'] != null) {
        // Save JWT token to secure storage
        final token = result['token'];
        await storage.write(key: _tokenKey, value: token);

        // Set token for API service
        ApiService.setToken(token);

        // Parse user data
        _currentUser = AppUser.fromMap(result['user']);

        _authStateController.add(_currentUser);
        print('✅ User logged in successfully');
        return {'success': true, 'user': _currentUser};
      } else {
        final error = result['error'] ?? 'Login failed';
        print('❌ Login error: $error');
        return {'success': false, 'error': error};
      }
    } catch (e) {
      print('❌ Unexpected error during login: $e');
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      print('👋 Logging out user');
      
      // Clear JWT token
      await storage.delete(key: _tokenKey);
      
      // Clear API token
      ApiService.clearToken();
      
      // Clear current user
      _currentUser = null;
      
      // Notify listeners
      _authStateController.add(null);
      
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  // Password reset (if needed in future)
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      // This could call a backend endpoint for password reset
      return {
        'success': false,
        'error': 'Password reset not implemented yet'
      };
    } catch (e) {
      return {'success': false, 'error': 'An error occurred: $e'};
    }
  }

  static void dispose() {
    _authStateController.close();
  }
}
