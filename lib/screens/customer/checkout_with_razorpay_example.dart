// Example: Integration with Order Checkout Screen
// Add this to your checkout or payment screen

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/payment_service.dart';

import '../../utils/app_colors.dart';
import '../../utils/error_handler.dart';

class CheckoutWithRazorpayExample extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  const CheckoutWithRazorpayExample({super.key, 
    required this.orderId,
    required this.totalAmount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  @override
  State<CheckoutWithRazorpayExample> createState() =>
      _CheckoutWithRazorpayExampleState();
}

class _CheckoutWithRazorpayExampleState
    extends State<CheckoutWithRazorpayExample> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Initialize Razorpay payment handlers
    PaymentService.initRazorpay(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    PaymentService.dispose();
    super.dispose();
  }

  /// Handle successful payment
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success!');
    print('   Payment ID: ${response.paymentId}');
    print('   Order ID: ${response.orderId}');
    print('   Signature: ${response.signature}');

    setState(() => _isProcessing = true);

    try {
      // Verify payment on backend
      final verifyResponse = await PaymentService.verifyPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
        orderId: widget.orderId,
      );

      if (verifyResponse['success']) {
        // Payment verified successfully
        _showSuccessDialog();

        // Optional: Update order status in your app
        // await OrderService.updateOrderStatus(widget.orderId, 'Confirmed');
      } else {
        _showErrorDialog(ErrorHandler.formatError(
            'Payment verification failed: ${verifyResponse['error']}'));
      }
    } catch (e) {
      _showErrorDialog(ErrorHandler.formatError('Error verifying payment: $e'));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Handle payment failure
  void _handlePaymentFailure(PaymentFailureResponse response) {
    print('❌ Payment Failed!');
    print('   Error Code: ${response.code}');
    print('   Error Message: ${response.message}');

    _showErrorDialog(
        ErrorHandler.formatError('Payment failed: ${response.message}'));
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 External Wallet: ${response.walletName}');
    _showInfoDialog('Using ${response.walletName} wallet');
  }

  /// Initiate payment process
  Future<void> _initiatePayment() async {
    setState(() => _isProcessing = true);

    try {
      // Step 1: Create payment order on backend
      final orderResponse = await PaymentService.createPaymentOrder(
        orderId: widget.orderId,
        amount: widget.totalAmount,
        currency: 'INR',
      );

      if (!orderResponse['success']) {
        _showErrorDialog(ErrorHandler.formatError(
            'Failed to create order: ${orderResponse['error']}'));
        setState(() => _isProcessing = false);
        return;
      }

      // Step 2: Open Razorpay checkout
      PaymentService.openCheckout(
        razorpayOrderId: orderResponse['razorpayOrderId'],
        amount: widget.totalAmount,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
        description: 'SmartCanteen Order #${widget.orderId}',
        key: orderResponse['key'],
      );
    } catch (e) {
      _showErrorDialog(
          ErrorHandler.formatError('Error initiating payment: $e'));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.successGreen, size: 28),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your payment has been confirmed!'),
            SizedBox(height: 12),
            Text('Order will be prepared shortly.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed, size: 28),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiatePayment(); // Retry payment
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order ID:'),
                      Text(widget.orderId,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:'),
                      Text(
                        '₹${widget.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer:'),
                      Text(widget.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryOrange),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.credit_card,
                        color: AppColors.primaryOrange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Razorpay Payment',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Credit Card, Debit Card, UPI, Wallet',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pay Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _initiatePayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Pay Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment is secure and encrypted',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
