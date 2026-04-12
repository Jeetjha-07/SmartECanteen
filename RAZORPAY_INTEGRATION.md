# ✅ Razorpay Integration - Complete Implementation

## 📋 What's Been Integrated

### **Backend (Node.js)**
- ✅ Created `/backend/routes/payments.js` with all Razorpay APIs
- ✅ Added payment routes to `server.js`
- ✅ Updated Order model with Razorpay fields
- ✅ Added Razorpay SDK to `package.json`

### **Frontend (Flutter)**
- ✅ Added `razorpay_flutter` SDK to `pubspec.yaml`
- ✅ Created `lib/config/razorpay_config.dart` for configuration
- ✅ Created `lib/services/payment_service.dart` for payment handling
- ✅ Created example integration screen

---

## 🚀 Quick Start Setup (5 Minutes)

### **Step 1: Get Razorpay Keys**
1. Visit https://dashboard.razorpay.com
2. Go to Settings → API Keys
3. Copy your **Key ID** (public) and **Key Secret** (private)

### **Step 2: Configure Backend**
Update `.env` file:
```env
RAZORPAY_KEY_ID=rzp_live_YOUR_ACTUAL_KEY
RAZORPAY_KEY_SECRET=YOUR_ACTUAL_SECRET
```

### **Step 3: Configure Frontend**
Update `lib/config/razorpay_config.dart`:
```dart
static const String KEY_ID = 'rzp_live_YOUR_ACTUAL_KEY';
```

### **Step 4: Install Dependencies**
```bash
# Backend
cd backend
npm install razorpay
npm install

# Frontend
cd ..
flutter pub get
```

### **Step 5: Test Integration**
```bash
# Start backend
npm run dev

# Start Flutter app (in another terminal)
flutter run
```

---

## 📁 New Files Created

### **Backend**
- `backend/routes/payments.js` - Razorpay API endpoints (4 endpoints)
- Updated: `backend/server.js` - Added payment routes
- Updated: `backend/models/Order.js` - Added payment fields
- Updated: `backend/package.json` - Added Razorpay SDK

### **Frontend**
- `lib/config/razorpay_config.dart` - Configuration file
- `lib/services/payment_service.dart` - Payment service class
- `lib/screens/customer/checkout_with_razorpay_example.dart` - Example implementation

### **Documentation**
- `RAZORPAY_SETUP.md` - Complete setup guide with test credentials
- This file!

---

## 🔌 Available API Endpoints

### **1. Create Payment Order**
```bash
POST /api/payments/create-order
Authorization: Bearer <JWT_TOKEN>

Body: {
  "orderId": "order_123",
  "amount": 500.00,
  "currency": "INR"
}

Response: {
  "success": true,
  "razorpayOrderId": "order_ABC123",
  "amount": 50000,
  "key": "rzp_live_..."
}
```

### **2. Verify Payment**
```bash
POST /api/payments/verify-payment
Authorization: Bearer <JWT_TOKEN>

Body: {
  "razorpay_order_id": "order_ABC123",
  "razorpay_payment_id": "pay_XYZ789",
  "razorpay_signature": "signature_hash",
  "orderId": "order_123"
}

Response: {
  "success": true,
  "message": "Payment verified successfully",
  "order": { ... order details ... }
}
```

### **3. Get Payment Status**
```bash
GET /api/payments/payment-status/:orderId
Authorization: Bearer <JWT_TOKEN>

Response: {
  "success": true,
  "paymentStatus": "Completed",
  "paymentMethod": "Razorpay",
  "razorpay_payment_id": "pay_XYZ789"
}
```

### **4. Payment Webhook**
```bash
POST /api/payments/webhook
(No authentication required - direct from Razorpay)

Handles: payment.authorized, payment.captured, payment.failed, order.paid
```

---

## 💳 Payment Methods Supported

- 🔹 **Credit Cards** (Visa, Mastercard, Amex)
- 🔹 **Debit Cards**
- 🔹 **UPI** (Google Pay, PhonePe, Paytm, BHIM)
- 🔹 **Wallets** (Paytm, Amazon Pay, Mobikwik)
- 🔹 **NetBanking**
- 🔹 **International Cards**

---

## 🔒 Security Features

✅ **Signature Verification** - Validates every payment
✅ **JWT Authentication** - All endpoints require valid token
✅ **Server-side Verification** - Payment verified on backend
✅ **PCI DSS Compliant** - Razorpay handles card data
✅ **No Card Data Stored** - Only Razorpay IDs stored in database

---

## 📊 Order Model Updates

### New Fields Added to Order:
```javascript
razorpay_order_id: String,      // Razorpay order ID
razorpay_payment_id: String,    // Razorpay payment ID
paymentVerifiedAt: Date,         // When payment was verified
paymentMethod: 'Razorpay'        // Payment method indicator
```

---

## 🛠️ How to Integrate in Your Order Flow

### **Step 1: Initialize Payment Service** (in main.dart)
```dart
import 'services/payment_service.dart';

void main() {
  PaymentService.initRazorpay(
    onSuccess: (response) { /* handle success */ },
    onFailure: (response) { /* handle failure */ },
    onWallet: (response) { /* handle wallet */ },
  );
  runApp(const MyApp());
}
```

### **Step 2: In Your Checkout Screen**
```dart
// Button to initiate payment
ElevatedButton(
  onPressed: () async {
    // Create order
    final orderResponse = await PaymentService.createPaymentOrder(
      orderId: orderId,
      amount: totalAmount,
    );
    
    if (orderResponse['success']) {
      // Open checkout
      PaymentService.openCheckout(
        razorpayOrderId: orderResponse['razorpayOrderId'],
        amount: totalAmount,
        customerName: name,
        customerEmail: email,
        customerPhone: phone,
        key: orderResponse['key'],
      );
    }
  },
  child: const Text('Pay with Razorpay'),
)
```

### **Step 3: Handle Payment Success**
```dart
void onPaymentSuccess(PaymentSuccessResponse response) async {
  // Verify on backend
  final result = await PaymentService.verifyPayment(
    razorrayOrderId: response.orderId!,
    razorpayPaymentId: response.paymentId!,
    razorpaySignature: response.signature!,
    orderId: orderId,
  );
  
  if (result['success']) {
    // Order is now paid! Update UI
    showSuccessDialog();
  }
}
```

---

## 🧪 Testing with Test Credentials

You can test with Razorpay's test keys:

### Test Card Details:
| Field | Value |
|-------|-------|
| Card Number | 4111 1111 1111 1111 |
| Expiry | Any future date (e.g., 12/25) |
| CVV | Any 3 digits (e.g., 123) |
| OTP | 123456 |

### Test Payments Results:
- **Success scenarios** - Complete different payment flows
- **Failure scenarios** - Test error handling
- **Refund flows** - Test payment reversal

---

## ✔️ Implementation Checklist

- [ ] **Backend Setup**
  - [ ] Added `.env` with Razorpay keys
  - [ ] Ran `npm install razorpay`
  - [ ] Payment routes are accessible

- [ ] **Frontend Setup**
  - [ ] Ran `flutter pub get`
  - [ ] Updated `razorpay_config.dart` with KEY_ID
  - [ ] PaymentService is imported

- [ ] **Integration**
  - [ ] Initialized PaymentService in main.dart
  - [ ] Created checkout screen with payment button
  - [ ] Handles payment success/failure
  - [ ] Updates order status after payment

- [ ] **Testing**
  - [ ] Used test credentials to test
  - [ ] Verified order status changes in database
  - [ ] Tested error scenarios
  - [ ] Verified payment signature validation

- [ ] **Production Ready**
  - [ ] Switched to live Razorpay keys
  - [ ] Tested with real payment (small amount)
  - [ ] Verified webhook delivery
  - [ ] Set up customer email notifications

---

## 🐛 Troubleshooting

### **Problem: "Invalid Key ID"**
- Solution: Ensure KEY_ID is from correct environment (test vs live)
- Check `.env` has correct `RAZORPAY_KEY_ID`

### **Problem: "Signature Verification Failed"**
- Solution: Verify `RAZORPAY_KEY_SECRET` is correct
- Ensure no extra spaces or newlines in `.env`

### **Problem: "Order not found" when verifying**
- Solution: Ensure order exists in MongoDB
- Verify orderId parameter is correct

### **Problem: Razorpay widget not opening**
- Solution: Call `PaymentService.initRazorpay()` before opening checkout
- Ensure KEY_ID is valid

### **Problem: PaymentService not found**
- Solution: Run `flutter pub get`
- Verify `razorpay_flutter: ^1.3.8` in pubspec.yaml

---

## 📚 File Structure

```
SmartCanteen/
├── backend/
│   ├── routes/payments.js          ← NEW: Razorpay endpoints
│   ├── models/Order.js             ← UPDATED: Payment fields
│   ├── server.js                   ← UPDATED: Added /api/payments routes
│   └── package.json                ← UPDATED: Added razorpay SDK
│
├── lib/
│   ├── config/
│   │   └── razorpay_config.dart    ← NEW: Configuration
│   ├── services/
│   │   └── payment_service.dart    ← NEW: Payment handling
│   └── screens/customer/
│       └── checkout_with_razorpay_example.dart ← NEW: Example screen
│
├── pubspec.yaml                    ← UPDATED: razorpay_flutter added
├── RAZORPAY_SETUP.md              ← NEW: Setup guide
└── RAZORPAY_INTEGRATION.md        ← This file!
```

---

## 🎯 Next Steps

1. **Get Razorpay Credentials** → https://dashboard.razorpay.com
2. **Update .env files** with your keys
3. **Run tests** with test credentials
4. **Integrate into checkout screen** using the example code
5. **Test end-to-end** with real test payments
6. **Deploy to production** with live keys

---

## 📞 Support Resources

- **Razorpay Docs**: https://razorpay.com/docs/
- **Flutter SDK**: https://pub.dev/packages/razorpay_flutter
- **API Reference**: https://razorpay.com/docs/api/
- **Support**: https://razorpay.com/support

---

## ✨ Status: Ready to Use!

Everything is set up and ready for integration. Just add your Razorpay API keys and you're all set to accept payments! 🎉
