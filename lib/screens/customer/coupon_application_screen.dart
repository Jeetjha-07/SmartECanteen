import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/coupon_service.dart';
import '../../models/restaurant.dart';
import '../../utils/app_colors.dart';

class CouponApplicationScreen extends StatefulWidget {
  final Restaurant restaurant;
  final double orderAmount;

  const CouponApplicationScreen({
    super.key,
    required this.restaurant,
    required this.orderAmount,
  });

  @override
  State<CouponApplicationScreen> createState() =>
      _CouponApplicationScreenState();
}

class _CouponApplicationScreenState extends State<CouponApplicationScreen> {
  final TextEditingController _couponController = TextEditingController();
  Map<String, dynamic>? validationResult;
  bool isValidating = false;

  void _validateCoupon() async {
    if (_couponController.text.isEmpty) {
      _showError('Please enter a coupon code');
      return;
    }

    setState(() {
      isValidating = true;
    });

    final result =
        await Provider.of<CouponService>(context, listen: false).validateCoupon(
      code: _couponController.text,
      restaurantId: widget.restaurant.restaurantId,
      orderAmount: widget.orderAmount,
    );

    setState(() {
      isValidating = false;
      validationResult = result;
    });

    if (result != null && !result['valid']) {
      _showError(result['error'] ?? 'Invalid coupon');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Coupon'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Amount
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Amount',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${widget.orderAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Coupon Input
              const Text('Coupon Code',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isValidating ? null : _validateCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                    child: isValidating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Validation Result
              if (validationResult != null && validationResult!['valid'])
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Coupon Applied Successfully',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount'),
                          Text(
                            '₹${validationResult!['discount'].toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Final Amount',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            '₹${validationResult!['finalAmount'].toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primaryOrange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, validationResult);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                          ),
                          child: const Text('Apply Coupon & Continue',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (validationResult != null && !validationResult!['valid'])
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          validationResult!['error'] ?? 'Invalid coupon',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                    child: const Text('Continue Without Coupon',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),

              const SizedBox(height: 24),

              // Available Coupons
              const Text('Available Coupons',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Consumer<CouponService>(
                builder: (context, couponService, _) {
                  couponService
                      .getCouponsByRestaurant(widget.restaurant.restaurantId);
                  final coupons = couponService.availableCoupons;

                  if (coupons.isEmpty) {
                    return const Text('No coupons available',
                        style: TextStyle(color: Colors.grey));
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(coupon.code,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(coupon.description),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              coupon.displayDiscount,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                          onTap: () {
                            _couponController.text = coupon.code;
                            _validateCoupon();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
}
