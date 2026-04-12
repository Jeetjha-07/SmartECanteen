# 🎯 Razorpay Integration Setup Guide

## Prerequisites

- Razorpay Account (https://razorpay.com)
- Backend running on your server
- Flutter app with Razorpay SDK

---

## 1️⃣ Backend Setup

### Step 1: Add Environment Variables

Add these to your `.env` file:

```env
# Razorpay Live Keys (get from Razorpay Dashboard)
RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_LIVE_KEY_SECRET

# Or use Test Keys during development:
# RAZORPAY_KEY_ID=rzp_test_YOUR_TEST_KEY_ID
# RAZORPAY_KEY_SECRET=YOUR_TEST_KEY_SECRET
```

### Step 2: Install Razorpay Package

```bash
cd backend
npm install razorpay
npm install
```

### Step 3: Verify Routes

The payment routes are already added to `server.js`:
```javascript
app.use('/api/payments', checkMongoConnection, require('./routes/payments'));
```

---

## 2️⃣ Frontend Setup

### Step 1: Update pubspec.yaml

Already done ✅ - `razorpay_flutter: ^1.3.8`

### Step 2: Install Dependencies

```bash
cd project_root
flutter pub get
```

### Step 3: Configure Razorpay Key

Update your key in `lib/config/razorpay_config.dart`:

```dart
static const String KEY_ID = 'rzp_live_YOUR_KEY_ID'; // Your live key
```

### Step 4: Initialize in Main App

Add to your `main.dart`:

```dart
import 'services/payment_service.dart';

void main() {
  // Initialize Razorpay
  PaymentService.initRazorpay(
    onSuccess: (response) {
      // Handle success
    },
    onFailure: (response) {
      // Handle failure
    },
    onWallet: (response) {
      // Handle external wallet
    },
  );
  
  runApp(const MyApp());
}
```

---

## 3️⃣ How to Get Razorpay Credentials

### From Razorpay Dashboard:

1. **Login** to https://dashboard.razorpay.com
2. **Go to Settings** → **API Keys**
3. **Copy**:
   - `Key ID` (public key, safe to use in frontend)
   - `Key Secret` (secret key, use only in backend)

### Test Credentials:

For testing, you can use:
- **Test Card**: `4111 1111 1111 1111`
- **Expiry**: Any future date (e.g., 12/25)
- **CVV**: Any 3 digits (e.g., 123)

---

## 4️⃣ API Endpoints

### Create Payment Order
```bash
POST /api/payments/create-order
Headers: Authorization: Bearer <JWT_TOKEN>
Body: {
  "orderId": "order_123",
  "amount": 500.00,
  "currency": "INR"
}

Response: {
  "success": true,
  "razorpayOrderId": "order_IlGWxBZW9O8zJ8",
  "amount": 50000,
  "key": "rzp_live_YOUR_KEY"
}
```

### Verify Payment
```bash
POST /api/payments/verify-payment
Headers: Authorization: Bearer <JWT_TOKEN>
Body: {
  "razorpay_order_id": "order_IlGWxBZW9O8zJ8",
  "razorpay_payment_id": "pay_IlGWxBZW9O8zJ8",
  "razorpay_signature": "9ef4dffbfd84f1318f6739a3ce19f9d85851857ae648f114332d8401e0949a3d",
  "orderId": "order_123"
}

Response: {
  "success": true,
  "message": "Payment verified successfully",
  "order": { ... }
}
```

### Get Payment Status
```bash
GET /api/payments/payment-status/:orderId
Headers: Authorization: Bearer <JWT_TOKEN>

Response: {
  "success": true,
  "paymentStatus": "Completed",
  "paymentMethod": "Razorpay",
  "razorpay_payment_id": "pay_IlGWxBZW9O8zJ8",
  "razorpay_order_id": "order_IlGWxBZW9O8zJ8"
}
```

---

## 5️⃣ Usage in Flutter

### Initialize Payment Service:
```dart
import 'services/payment_service.dart';

// In your checkout screen
PaymentService.initRazorpay(
  onSuccess: _handlePaymentSuccess,
  onFailure: _handlePaymentFailure,
  onWallet: _handleExternalWallet,
);
```

### Create Order and Open Checkout:
```dart
// Step 1: Create payment order on backend
final orderResponse = await PaymentService.createPaymentOrder(
  orderId: orderId,
  amount: 500.00,
);

if (orderResponse['success']) {
  // Step 2: Open Razorpay checkout
  PaymentService.openCheckout(
    razorpayOrderId: orderResponse['razorpayOrderId'],
    amount: 500.00,
    customerName: 'John Doe',
    customerEmail: 'john@example.com',
    customerPhone: '9876543210',
    key: orderResponse['key'],
  );
}
```

### Handle Payment Success:
```dart
void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  // Verify payment on backend
  final verifyResponse = await PaymentService.verifyPayment(
    razorrayOrderId: response.orderId!,
    razorpayPaymentId: response.paymentId!,
    razorpaySignature: response.signature!,
    orderId: orderId,
  );

  if (verifyResponse['success']) {
    // Show success message
    // Update UI
  }
}
```

---

## 6️⃣ Testing Checklist

- [ ] Razorpay account created
- [ ] API keys added to `.env`
- [ ] `razorpay_flutter` package installed
- [ ] Payment routes added to backend
- [ ] Order model updated
- [ ] Payment service created
- [ ] Checkout screen integrated
- [ ] Test payment created (test mode)
- [ ] Payment verified successfully
- [ ] Order status updated

---

## 7️⃣ Common Issues & Fixes

### Issue: Payment signature mismatch
**Solution**: Ensure `KEY_SECRET` is correct and not exposed in frontend

### Issue: Razorpay widget not opening
**Solution**: Verify KEY_ID is correct and Razorpay is initialized before opening

### Issue: Payment verified but order not updating
**Solution**: Check JWT token is valid and order exists in database

### Issue: CORS error
**Solution**: Ensure CORS is enabled in backend (already done in `server.js`)

---

## 8️⃣ Going Live

When moving to production:

1. **Get Live Keys** from Razorpay Dashboard
2. **Update `.env`** with live keys
3. **Update `razorpay_config.dart`** with live KEY_ID
4. **Test with real cards** (very small amount)
5. **Deploy to production**

---

## 📚 Additional Resources

- Razorpay API Docs: https://razorpay.com/docs/
- Flutter SDK: https://pub.dev/packages/razorpay_flutter
- Integration Examples: https://github.com/razorpay/razorpay-flutter

---

**Status**: ✅ Ready for Integration
