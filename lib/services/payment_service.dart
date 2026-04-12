import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';
import 'dart:convert';
import 'auth_service.dart';

class PaymentService {
  static final Razorpay _razorpay = Razorpay();

  /// Initialize Razorpay with event handlers
  static void initRazorpay({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      print('✅ Payment Success: ${response.paymentId}');
      onSuccess(response);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      print('❌ Payment Error: ${response.code} - ${response.message}');
      onFailure(response);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      print('💳 External Wallet: ${response.walletName}');
      onWallet(response);
    });
  }

  /// Create a payment order on backend
  static Future<Map<String, dynamic>> createPaymentOrder({
    required String orderId,
    required double amount,
    String currency = 'INR',
  }) async {
    try {
      print('📝 Creating payment order for: $orderId, Amount: ₹$amount');

      final response = await ApiService().post(
        '${ApiService.baseUrl}/payments/create-order',
        body: {
          'orderId': orderId,
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': currency,
        },
      );

      if (response != null) {
        final data = response is String ? jsonDecode(response) : response;

        if (data is Map && data['success'] == true) {
          print('✅ Payment order created: ${data['razorpayOrderId']}');
          return {
            'success': true,
            'razorpayOrderId': data['razorpayOrderId'],
            'amount': data['amount'],
            'currency': data['currency'],
            'key': data['key'],
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to create payment order',
      };
    } catch (e) {
      print('❌ Error creating payment order: $e');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Verify payment on backend
  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    try {
      print('🔐 Verifying payment: $razorpayPaymentId');

      final response = await ApiService().post(
        '${ApiService.baseUrl}/payments/verify-payment',
        body: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'orderId': orderId,
        },
      );

      if (response != null) {
        final data = response is String ? jsonDecode(response) : response;

        if (data is Map && data['success'] == true) {
          print('✅ Payment verified successfully!');
          return {
            'success': true,
            'message': data['message'] ?? 'Payment verified',
            'order': data['order'],
          };
        }
      }

      return {
        'success': false,
        'error': 'Payment verification failed',
      };
    } catch (e) {
      print('❌ Error verifying payment: $e');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Open Razorpay checkout
  static void openCheckout({
    required String razorpayOrderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String description = 'SmartCanteen Food Order',
    String key = '',
  }) {
    try {
      print('💳 Opening Razorpay checkout...');

      var options = {
        'key': key.isNotEmpty ? key : 'rzp_test_YOUR_TEST_KEY',
        'order_id': razorpayOrderId,
        'amount': (amount * 100).toInt(), // amount in paise
        'currency': 'INR',
        'name': 'SmartCanteen',
        'description': description,
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
          'name': customerName,
        },
        'external': {
          'wallets': ['paytm', 'phonepe', 'googlepay']
        },
        'theme': {
          'color': '#FF6B35' // Primary orange
        }
      };

      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening checkout: $e');
      rethrow;
    }
  }

  /// Get payment status
  static Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    try {
      print('📊 Getting payment status for order: $orderId');

      final response = await ApiService().get(
        '${ApiService.baseUrl}/payments/payment-status/$orderId',
      );

      if (response != null) {
        final data = response is String ? jsonDecode(response) : response;

        if (data is Map && data['success'] == true) {
          return {
            'success': true,
            'paymentStatus': data['paymentStatus'],
            'paymentMethod': data['paymentMethod'],
            'razorpay_payment_id': data['razorpay_payment_id'],
            'razorpay_order_id': data['razorpay_order_id'],
          };
        }
      }

      return {
        'success': false,
        'error': 'Failed to get payment status',
      };
    } catch (e) {
      print('❌ Error getting payment status: $e');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Dispose Razorpay instance
  static void dispose() {
    _razorpay.clear();
  }
}
