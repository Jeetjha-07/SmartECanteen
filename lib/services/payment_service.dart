import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';
import 'dart:convert';

class PaymentService {
  static final Razorpay _razorpay = Razorpay();

  /// Initialize Razorpay with event handlers
  static void initRazorpay({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
      print('✅ Payment Success: ${response.paymentId}');
      onSuccess(response);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
      print('❌ Payment Error: ${response.code} - ${response.message}');
      onFailure(response);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
        (ExternalWalletResponse response) {
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
      print('═══════════════════════════════════════════════════');
      print('💳 CREATING PAYMENT ORDER');
      print('   Order ID: $orderId');
      print('   Amount: ₹$amount INR (${(amount * 100).toInt()} paise)');
      print('   API Endpoint: ${ApiService.baseUrl}/payments/create-order');
      print('═══════════════════════════════════════════════════');

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
          print('✅ Payment order created successfully');
          print('   Razorpay Order ID: ${data['razorpayOrderId']}');
          print('   API Key: ${data['key']?.substring(0, 10)}...');
          return {
            'success': true,
            'razorpayOrderId': data['razorpayOrderId'],
            'amount': data['amount'],
            'currency': data['currency'],
            'key': data['key'],
          };
        }
      }

      print('❌ Payment order creation failed: Invalid response');
      return {
        'success': false,
        'error': 'Failed to create payment order',
      };
    } catch (e) {
      print('❌ ERROR creating payment order:');
      print('   Error: $e');
      print('═══════════════════════════════════════════════════');
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
      print('═══════════════════════════════════════════════════');
      print('🔐 VERIFYING PAYMENT SIGNATURE');
      print('   Razorpay Order ID: $razorpayOrderId');
      print('   Razorpay Payment ID: $razorpayPaymentId');
      print('   Signature: ${razorpaySignature.substring(0, 10)}...');
      print('═══════════════════════════════════════════════════');

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
          print('✅ Payment signature verified successfully!');
          print('   Order ID: ${data['order']?['_id'] ?? 'N/A'}');
          print(
              '   Payment Status: ${data['order']?['paymentStatus'] ?? 'N/A'}');
          return {
            'success': true,
            'message': data['message'] ?? 'Payment verified',
            'order': data['order'],
          };
        }
      }

      print('❌ Payment verification failed: Invalid response');
      return {
        'success': false,
        'error': 'Payment verification failed',
      };
    } catch (e) {
      print('❌ ERROR verifying payment:');
      print('   Error: $e');
      print('═══════════════════════════════════════════════════');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Open Razorpay checkout and store context for verification
  static Future<void> openCheckout({
    required String razorpayOrderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String description = 'SmartCanteen Food Order',
    String key = '',
    required Function(Map<String, dynamic>) onPaymentSuccess,
    required Function(String) onPaymentError,
  }) async {
    try {
      print('💳 Opening Razorpay checkout...');

      var options = {
        'key': key.isNotEmpty ? key : 'rzp_test_ScRRPFhQ53SYXe',
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

      // Remove previous listeners to avoid duplicate events
      _razorpay.clear();

      // Re-attach event handlers
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
          (PaymentSuccessResponse response) async {
        print('✅ Payment Success: ${response.paymentId}');

        // Verify payment on backend
        final verifyResult = await verifyPayment(
          razorpayOrderId: razorpayOrderId,
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
          orderId: razorpayOrderId,
        );

        if (verifyResult['success']) {
          print('✅ Payment verified and order placed!');
          onPaymentSuccess(verifyResult);
        } else {
          print('❌ Payment verification failed');
          onPaymentError(
              verifyResult['error'] ?? 'Payment verification failed');
        }
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
          (PaymentFailureResponse response) {
        print('❌ Payment Error: ${response.code} - ${response.message}');
        onPaymentError(response.message ?? 'Payment failed');
      });

      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
          (ExternalWalletResponse response) {
        print('💳 External Wallet: ${response.walletName}');
      });

      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening checkout: $e');
      onPaymentError('Error opening payment gateway: $e');
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
