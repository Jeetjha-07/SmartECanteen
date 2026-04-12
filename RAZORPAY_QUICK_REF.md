# 🚀 Razorpay Integration - Quick Reference

## 📌 Files You Need to Know

| File | Purpose | Status |
|------|---------|--------|
| `lib/config/razorpay_config.dart` | Store API keys | Need: Update KEY_ID with yours |
| `lib/services/payment_service.dart` | Payment logic | ✅ Ready to use |
| `lib/screens/customer/checkout_with_razorpay_example.dart` | Example screen | ✅ Copy to your checkout |
| `backend/routes/payments.js` | Payment API | ✅ Ready to use |
| `backend/models/Order.js` | Order data | ✅ Updated with payment fields |

---

## ⚡ 5-Minute Setup

```bash
# 1. Get keys from https://dashboard.razorpay.com → Settings → API Keys

# 2. Update .env file
echo "RAZORPAY_KEY_ID=rzp_live_YOUR_KEY" >> .env
echo "RAZORPAY_KEY_SECRET=YOUR_SECRET" >> .env

# 3. Install packages
cd backend && npm install && cd ..
flutter pub get

# 4. Update frontend config
# Edit: lib/config/razorpay_config.dart
# Change: KEY_ID = 'rzp_live_YOUR_KEY'

# 5. Start apps
npm run dev &  # backend
flutter run    # frontend
```

---

## 🎯 Core Methods

### **Initialize (main.dart)**
```dart
PaymentService.initRazorpay(
  onSuccess: (response) => print('Paid!'),
  onFailure: (response) => print('Failed!'),
  onWallet: (response) => print('Wallet!'),
);
```

### **Start Payment**
```dart
// Step 1: Create order
final order = await PaymentService.createPaymentOrder(
  orderId: '123', amount: 500.00
);

// Step 2: Open checkout
PaymentService.openCheckout(
  razorpayOrderId: order['razorpayOrderId'],
  amount: 50000,  // in paise
  key: order['key'],
);

// Step 3: Verify (auto-called by payment_service.dart)
```

### **Check Status**
```dart
final status = await PaymentService.getPaymentStatus(orderId: '123');
print(status['paymentStatus']); // 'Completed', 'Pending', etc.
```

---

## 🧪 Test Credentials

```
Card: 4111 1111 1111 1111
Expiry: 12/25
CVV: 123
OTP: 123456
```

---

## 📊 What Gets Saved in Database

```javascript
Order {
  _id: "order_123",
  amount: 500,
  paymentMethod: "Razorpay",
  paymentStatus: "Completed",
  
  // NEW FIELDS:
  razorpay_order_id: "order_ABC123",        // From Razorpay
  razorpay_payment_id: "pay_XYZ789",        // From payment
  paymentVerifiedAt: 2024-01-15T10:30:00Z   // When verified
}
```

---

## 🔗 Backend Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/payments/create-order` | POST | Create Razorpay order |
| `/api/payments/verify-payment` | POST | Verify payment signature |
| `/api/payments/payment-status/:orderId` | GET | Check payment status |
| `/api/payments/webhook` | POST | Razorpay webhook |

---

## ❌ Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| "Invalid Key ID" | Update `RAZORPAY_KEY_ID` in `.env` |
| "Signature verification failed" | Check `RAZORPAY_KEY_SECRET` in `.env` |
| Payment widget won't open | Call `initRazorpay()` before `openCheckout()` |
| "razorpay_flutter not found" | Run `flutter pub get` |
| Order not found during verify | Ensure order exists in MongoDB |

---

## 💡 Integration Pattern

```dart
// In your checkout button
onPressed: () async {
  // 1️⃣ Create Razorpay order on backend
  final orderResp = await PaymentService.createPaymentOrder(
    orderId: orderId,
    amount: totalAmount,
  );

  // 2️⃣ Open Razorpay checkout UI
  if (orderResp['success']) {
    PaymentService.openCheckout(
      razorpayOrderId: orderResp['razorpayOrderId'],
      amount: totalAmount,
      key: orderResp['key'],
      customerName: name,
      customerEmail: email,
      customerPhone: phone,
    );
  }

  // 3️⃣ PaymentService handles verification automatically
  //    and returns success/failure to callbacks
},
```

---

## ✅ Verification Checklist

- [ ] `.env` has `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET`
- [ ] `razorpay_config.dart` KEY_ID updated
- [ ] `flutter pub get` completed
- [ ] `npm install` completed (backend)
- [ ] Backend can access MongoDB
- [ ] Test payment with 4111 1111 1111 1111
- [ ] Order saved with razorpay_payment_id
- [ ] Ready for production keys

---

## 🚀 Next: Integration Steps

1. **Copy example screen** → Your checkout page
2. **Initialize PaymentService** → In main.dart
3. **Add payment button** → Your order screen
4. **Test with test keys** → Use card 4111 1111 1111 1111
5. **Switch to live keys** → When ready
6. **Monitor webhooks** → Verify payments in realtime

---

## 📚 Full Docs

See `RAZORPAY_SETUP.md` for complete setup guide with:
- Step-by-step instructions
- cURL examples for all endpoints
- Troubleshooting guide
- Production checklist

See `RAZORPAY_INTEGRATION.md` for complete implementation guide.

---

**Everything is ready! Just add your API keys and you're good to go! 🎉**
