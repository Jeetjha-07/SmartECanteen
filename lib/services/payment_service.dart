import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';
import 'dart:convert';
import 'dart:math' show min;

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
    required double totalAmount,
    required String restaurantId,
    required String customerId,
  }) async {
    try {
      print('═══════════════════════════════════════════════════');
      print('🔐 VERIFYING PAYMENT SIGNATURE');
      print('   Razorpay Order ID: $razorpayOrderId');
      print('   Razorpay Payment ID: $razorpayPaymentId');
      print('   Signature: ${razorpaySignature.substring(0, 10)}...');
      print('   Amount: ₹$totalAmount | Restaurant: $restaurantId');
      print('═══════════════════════════════════════════════════');

      final response = await ApiService().post(
        '${ApiService.baseUrl}/payments/verify-payment',
        body: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'orderId': orderId,
          'totalAmount': totalAmount,
          'restaurantId': restaurantId,
          'customerId': customerId,
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
    required String orderId,
    required String razorpayOrderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required double totalAmount,
    required String restaurantId,
    required String customerId,
    String description = 'SmartCanteen Food Order',
    String key = '',
    required Function(Map<String, dynamic>) onPaymentSuccess,
    required Function(String) onPaymentError,
  }) async {
    try {
      print('═══════════════════════════════════════════════════');
      print('💳 OPENING RAZORPAY CHECKOUT');
      print('   Order ID: $razorpayOrderId');
      print('   Amount: ₹${(amount).toStringAsFixed(2)}');
      print(
          '   API Key: ${key.isNotEmpty ? key.substring(0, min(key.length, 15)) + '...' : 'NOT PROVIDED'}');
      print('═══════════════════════════════════════════════════');

      // Validate key
      if (key.isEmpty) {
        print('❌ ERROR: API Key is empty!');
        onPaymentError(
            'Payment gateway not configured. Please contact support.');
        return;
      }

      if (key == 'rzp_test_YOUR_TEST_KEY') {
        print('❌ ERROR: API Key is using placeholder value!');
        onPaymentError('Payment gateway not properly configured.');
        return;
      }

      var options = {
        'key': key,
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

      print('   Checkout Options:');
      print('   - Currency: INR');
      print('   - Name: ${options['name']}');
      print('   - Email: $customerEmail');
      print('═══════════════════════════════════════════════════');

      // Remove previous listeners to avoid duplicate events
      _razorpay.clear();

      // Re-attach event handlers
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
          (PaymentSuccessResponse response) async {
        print('✅ PAYMENT SUCCESS');
        print('   Payment ID: ${response.paymentId}');
        print('   Order ID: ${response.orderId}');
        print(
            '   Signature: ${response.signature?.substring(0, min(response.signature?.length ?? 0, 15)) ?? 'N/A'}...');

        // Verify payment on backend
        final verifyResult = await verifyPayment(
          razorpayOrderId: razorpayOrderId,
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
          orderId: orderId,
          totalAmount: totalAmount,
          restaurantId: restaurantId,
          customerId: customerId,
        );

        if (verifyResult['success']) {
          print('✅ PAYMENT VERIFIED ON BACKEND');
          onPaymentSuccess(verifyResult);
        } else {
          print('❌ BACKEND VERIFICATION FAILED: ${verifyResult['error']}');
          onPaymentError(
              verifyResult['error'] ?? 'Payment verification failed');
        }
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
          (PaymentFailureResponse response) {
        print('❌ PAYMENT ERROR');
        print('   Code: ${response.code}');
        print('   Message: ${response.message}');
        onPaymentError(response.message ?? 'Payment failed');
      });

      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
          (ExternalWalletResponse response) {
        print('💳 EXTERNAL WALLET SELECTED: ${response.walletName}');
      });

      print('📱 Calling Razorpay.open()...');
      _razorpay.open(options);
      print('✓ Razorpay checkout called');
    } catch (e) {
      print('❌ ERROR OPENING CHECKOUT:');
      print('   Exception: $e');
      print('   Exception Type: ${e.runtimeType}');
      print('═══════════════════════════════════════════════════');
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
