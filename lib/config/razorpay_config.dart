/// Razorpay Configuration
class RazorpayConfig {
  // Razorpay API Key (Public key - safe to expose in frontend)
  // Get from: https://dashboard.razorpay.com → Settings → API Keys
  // TEST KEY: rzp_test_1rLKnTyIEFnLZN
  // Replace with your LIVE key for production
  static const String KEY_ID = 'rzp_test_1rLKnTyIEFnLZN'; // Update with your key
  
  // NOTE: Key Secret is NEVER used in frontend!
  // Key Secret is stored server-side in .env and used only for payment verification
  // DANGER: Never expose KEY_SECRET in frontend code!
}

/// Razorpay Options for payment
class RazorpayOptions {
  static Map<String, dynamic> getPaymentOptions({
    required String orderId,
    required String amount, // in paise (amount * 100)
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? description,
  }) {
    return {
      'key': RazorpayConfig.KEY_ID,
      'amount': amount, // amount in paise
      'currency': 'INR',
      'name': 'SmartCanteen',
      'description': description ?? 'Food Order Payment',
      'order_id': orderId, // This is the Razorpay order ID from backend
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay']
      },
      'theme': {
        'color': '#FF6B35' // Primary orange theme color
      }
    };
  }
}
