import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant.dart';
import '../../models/time_slot.dart';
import '../../services/cart_service.dart';
import '../../services/coupon_service.dart';
import '../../services/order_service.dart';
import '../../services/time_slot_service.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/error_handler.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Restaurant? restaurant;

  const CheckoutScreen({super.key, this.restaurant});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();
  String _paymentMethod = 'COD';
  bool _isProcessing = false;
  TimeSlot? _selectedTimeSlot;
  String? _appliedCouponCode;
  double _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    // Load time slots for the restaurant
    if (widget.restaurant != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final timeSlotService = context.read<TimeSlotService>();
        timeSlotService.getAvailableSlots(
          widget.restaurant!.restaurantId,
          DateTime.now(),
        );
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a delivery time slot'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }

    setState(() => _isProcessing = true);

    final cartService = context.read<CartService>();
    final totalWithDiscount = cartService.totalPrice - _discountAmount;

    // If payment method is Online (Card), process through Razorpay
    if (_paymentMethod == 'Card') {
      try {
        // Create an order first for MongoDB
        final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

        // Step 1: Create Razorpay order
        final orderResponse = await PaymentService.createPaymentOrder(
          orderId: orderId,
          amount: totalWithDiscount,
          currency: 'INR',
        );

        if (!orderResponse['success']) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ErrorHandler.formatError(
                'Failed to create payment order: ${orderResponse['error']}')),
            backgroundColor: AppColors.errorRed,
          ));
          return;
        }

        // Step 2: Validate user
        final currentUser = AuthService.currentUser;
        if (currentUser == null) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: AppColors.errorRed,
          ));
          return;
        }

        // Step 3: Open payment gateway with callbacks
        await PaymentService.openCheckout(
          orderId: orderId,
          razorpayOrderId: orderResponse['razorpayOrderId'],
          amount: totalWithDiscount,
          customerName: currentUser.name,
          customerEmail: currentUser.email,
          customerPhone: _phoneController.text.trim(),
          totalAmount: totalWithDiscount,
          restaurantId: widget.restaurant!.restaurantId,
          customerId: currentUser.uid,
          description: 'SmartCanteen Order',
          key: orderResponse['key'],
          onPaymentSuccess: (verifyResult) async {
            // Payment verified automatically in PaymentService
            // Now place the actual order
            if (!mounted) return;

            final result = await OrderService.placeOrder(
              cartItems: cartService.cartItems,
              totalAmount: totalWithDiscount,
              deliveryAddress: _addressController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              paymentMethod: 'Razorpay',
              restaurantId: widget.restaurant!.restaurantId,
              timeSlotId: _selectedTimeSlot!.id,
              couponCode: _appliedCouponCode,
            );

            if (!mounted) return;
            setState(() => _isProcessing = false);

            if (result['success']) {
              cartService.clearCart();
              _showSuccessDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ErrorHandler.formatError(
                    result['error'] ?? 'Failed to place order')),
                backgroundColor: AppColors.errorRed,
              ));
            }
          },
          onPaymentError: (errorMsg) {
            if (!mounted) return;
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(ErrorHandler.formatError('Payment failed: $errorMsg')),
              backgroundColor: AppColors.errorRed,
            ));
          },
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.formatError('Error: $e')),
          backgroundColor: AppColors.errorRed,
        ));
      }
      return;
    }

    // For COD, place order directly
    final result = await OrderService.placeOrder(
      cartItems: cartService.cartItems,
      totalAmount: totalWithDiscount,
      deliveryAddress: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      paymentMethod: _paymentMethod,
      restaurantId: widget.restaurant!.restaurantId,
      timeSlotId: _selectedTimeSlot!.id,
      couponCode: _appliedCouponCode,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result['success']) {
      cartService.clearCart();
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ErrorHandler.formatError(
            result['error'] ?? 'Failed to place order')),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  /// Show success dialog after order is placed
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.successGreen, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('Order Placed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed successfully.\nThe restaurant will start preparing it shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.primaryOrange),
                  SizedBox(width: 6),
                  Text(
                    'Track in Orders tab',
                    style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Track My Order'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    _sectionTitle('Order Summary'),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          ...cartService.cartItems.map((cartItem) => ListTile(
                                dense: true,
                                title: Text(cartItem.foodItem.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text('Qty: ${cartItem.quantity}',
                                    style: const TextStyle(fontSize: 12)),
                                trailing: Text(
                                  '₹${(cartItem.foodItem.price * cartItem.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryOrange),
                                ),
                              )),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(
                                  '₹${cartService.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primaryOrange),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Delivery Details
                    _sectionTitle('Delivery Details'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter delivery address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (v.length < 10 || v.length > 10) {
                          return 'Enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Time Slot Selection
                    if (widget.restaurant != null) ...[
                      _sectionTitle('Select Delivery Time'),
                      const SizedBox(height: 12),
                      Consumer<TimeSlotService>(
                        builder: (context, timeSlotService, _) {
                          if (timeSlotService.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryOrange,
                              ),
                            );
                          }

                          if (timeSlotService.timeSlots.isEmpty) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No time slots available for ${DateTime.now().toString().split(' ')[0]}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: timeSlotService.timeSlots.map((slot) {
                              final isSelected =
                                  _selectedTimeSlot?.id == slot.id;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTimeSlot = slot),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryOrange
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryOrange
                                          : Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${slot.startTime} - ${slot.endTime}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        '${slot.capacity - slot.currentOrders} available',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white70
                                              : AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Coupon Code
                    _sectionTitle('Apply Coupon (Optional)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _couponController,
                            decoration: const InputDecoration(
                              labelText: 'Coupon Code',
                              prefixIcon: Icon(Icons.local_offer_outlined),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _applyCoupon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_appliedCouponCode != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.successGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '✓ Coupon Applied: $_appliedCouponCode',
                              style: const TextStyle(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: _removeCoupon,
                              child: const Icon(
                                Icons.close,
                                color: AppColors.successGreen,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount'),
                            Text(
                              '-₹${_discountAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Payment Method
                    _sectionTitle('Payment Method'),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                const Icon(Icons.money,
                                    color: AppColors.successGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cash on Delivery',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            value: 'COD',
                            groupValue: _paymentMethod,
                            activeColor: AppColors.primaryOrange,
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v!),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                const Icon(Icons.payment,
                                    color: AppColors.primaryOrange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Razorpay (Cards, UPI, Wallets)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            value: 'Card',
                            groupValue: _paymentMethod,
                            activeColor: AppColors.primaryOrange,
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom Place Order button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Place Order • ₹${cartService.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a coupon code'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }

    if (widget.restaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Restaurant information not available'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }

    try {
      final cartService = context.read<CartService>();
      final couponService = context.read<CouponService>();
      final currentUser = AuthService.currentUser;

      // Call actual API validation with restaurant ID and user ID
      final result = await couponService.validateCoupon(
        code: code,
        restaurantId: widget.restaurant!.restaurantId,
        orderAmount: cartService.totalPrice,
        customerId: currentUser?.uid,
      );

      if (result != null && result['valid'] == true) {
        setState(() {
          _appliedCouponCode = code;
          _discountAmount = result['discount'] ?? 0.0;
        });

        String discountText = '';
        final coupon = result['coupon'];
        if (coupon != null && coupon.discountType == 'percentage') {
          discountText = '${coupon.discountValue}% discount';
        } else {
          discountText = 'fixed discount';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Coupon applied! ₹${_discountAmount.toStringAsFixed(0)} $discountText',
          ),
          backgroundColor: AppColors.successGreen,
        ));
      } else {
        if (!mounted) return;
        final errorMsg =
            ErrorHandler.formatError(result?['error'] ?? 'Invalid coupon code');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ErrorHandler.formatError('Error: ${e.toString()}')),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _discountAmount = 0;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Coupon removed'),
    ));
  }
}
