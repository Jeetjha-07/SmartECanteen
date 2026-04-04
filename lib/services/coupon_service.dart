import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/coupon.dart';
import 'dart:convert';

class CouponService extends ChangeNotifier {
  List<Coupon> coupons = [];
  List<Coupon> availableCoupons = [];
  Coupon? selectedCoupon;
  bool isLoading = false;
  String? error;

  final ApiService _apiService = ApiService();

  // Create new coupon (restaurant owner)
  Future<bool> createCoupon(Map<String, dynamic> couponData) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiService.baseUrl}/coupons/create',
        body: couponData,
      );

      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error creating coupon: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get coupons for a restaurant
  Future<void> getCouponsByRestaurant(String restaurantId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '${ApiService.baseUrl}/coupons/restaurant/$restaurantId',
      );

      if (response != null) {
        final List<dynamic> data =
            response is String ? jsonDecode(response) : response;
        coupons = (data)
            .map((item) => Coupon.fromJson(item as Map<String, dynamic>))
            .toList();
        availableCoupons = coupons.where((c) => c.isValid).toList();
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching coupons: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get my coupons (logged-in restaurant owner)
  Future<void> getMyCoupons() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '${ApiService.baseUrl}/coupons/owner/my-coupons',
      );

      if (response != null) {
        final List<dynamic> data =
            response is String ? jsonDecode(response) : response;
        coupons = (data)
            .map((item) => Coupon.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      error = e.toString();
      print('Error fetching my coupons: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Validate and apply coupon
  Future<Map<String, dynamic>?> validateCoupon({
    required String code,
    required String restaurantId,
    required double orderAmount,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiService.baseUrl}/coupons/validate',
        body: {
          'code': code,
          'restaurantId': restaurantId,
          'orderAmount': orderAmount,
        },
      );

      if (response != null) {
        final data = response is String ? jsonDecode(response) : response;
        selectedCoupon = Coupon.fromJson(data['coupon']);
        return {
          'valid': true,
          'discount': data['discount'],
          'finalAmount': data['finalAmount'],
          'coupon': selectedCoupon,
        };
      }
      return null;
    } catch (e) {
      error = e.toString();
      print('Error validating coupon: $e');
      return {
        'valid': false,
        'error': e.toString(),
      };
    }
  }

  // Update coupon
  Future<bool> updateCoupon(
      String couponId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.put(
        '${ApiService.baseUrl}/coupons/$couponId',
        body: updates,
      );

      if (response != null) {
        await getMyCoupons(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error updating coupon: $e');
      return false;
    }
  }

  // Delete coupon
  Future<bool> deleteCoupon(String couponId) async {
    try {
      final response = await _apiService.delete(
        '${ApiService.baseUrl}/coupons/$couponId',
      );

      if (response != null) {
        await getMyCoupons(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      error = e.toString();
      print('Error deleting coupon: $e');
      return false;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void clearSelection() {
    selectedCoupon = null;
    notifyListeners();
  }
}
