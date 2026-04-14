import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/coupon_service.dart';
import '../../models/coupon.dart';
import '../../utils/app_colors.dart';

class RestaurantCouponsScreen extends StatefulWidget {
  const RestaurantCouponsScreen({super.key});

  @override
  State<RestaurantCouponsScreen> createState() =>
      _RestaurantCouponsScreenState();
}

class _RestaurantCouponsScreenState extends State<RestaurantCouponsScreen> {
  @override
  void initState() {
    super.initState();
    // Load coupons when screen opens
    Future.microtask(() {
      context.read<CouponService>().getMyCoupons();
    });
  }

  Future<void> _refreshCoupons() async {
    context.read<CouponService>().getMyCoupons();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Coupons'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCouponDialog(context),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCoupons,
        color: AppColors.primaryOrange,
        child: Consumer<CouponService>(
          builder: (context, couponService, _) {
            if (couponService.isLoading && couponService.coupons.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (couponService.error != null && couponService.coupons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.errorRed, size: 48),
                    const SizedBox(height: 12),
                    Text('Error: ${couponService.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshCoupons,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (couponService.coupons.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.primaryOrange,
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Coupons Yet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Create coupons to attract more customers and boost sales!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateCouponDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Coupon'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: couponService.coupons.length,
              itemBuilder: (context, index) {
                final coupon = couponService.coupons[index];
                return _CouponCard(
                  coupon: coupon,
                  onEdit: () => _showEditCouponDialog(context, coupon),
                  onDelete: () => _showDeleteConfirmDialog(context, coupon),
                  onToggleActive: () => _toggleCouponActive(context, coupon),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateCouponDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateCouponDialog(
        onCreate: () => _refreshCoupons(),
      ),
    );
  }

  void _showEditCouponDialog(BuildContext context, Coupon coupon) {
    showDialog(
      context: context,
      builder: (_) => _EditCouponDialog(
        coupon: coupon,
        onUpdate: () => _refreshCoupons(),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Coupon coupon) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Coupon?'),
        content: Text('Are you sure you want to delete "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success =
                  await context.read<CouponService>().deleteCoupon(coupon.id);
              if (!mounted) return;
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coupon deleted')),
                );
                _refreshCoupons();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete coupon'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCouponActive(BuildContext context, Coupon coupon) async {
    final success = await context.read<CouponService>().updateCoupon(
      coupon.id,
      {'isActive': !coupon.isActive},
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(coupon.isActive ? 'Coupon deactivated' : 'Coupon activated'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update coupon'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isExpired = coupon.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: coupon.isActive
                ? (isExpired ? Colors.grey[300]! : AppColors.successGreen)
                : Colors.red[200]!,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with code and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          coupon.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coupon.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Discount display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        coupon.displayDiscount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details row
            Row(
              children: [
                Expanded(
                  child: _DetailChip(
                    label: 'Min Order',
                    value: '₹${coupon.minOrderValue}',
                    icon: Icons.shopping_cart_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetailChip(
                    label: 'Max Uses',
                    value: coupon.maxUses?.toString() ?? 'Unlimited',
                    icon: Icons.repeat_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetailChip(
                    label: 'Used',
                    value: '${coupon.usedCount}/${coupon.maxUses ?? "-"}',
                    icon: Icons.check_circle_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Validity info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red[50]
                    : (coupon.isActive ? Colors.green[50] : Colors.blue[50]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired
                        ? Icons.schedule_outlined
                        : (coupon.isActive
                            ? Icons.check_circle_outlined
                            : Icons.pause_circle_outlined),
                    size: 18,
                    color: isExpired
                        ? Colors.red
                        : (coupon.isActive ? Colors.green : Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isExpired
                          ? 'Expired on ${dateFormat.format(coupon.validUntil)}'
                          : '${dateFormat.format(coupon.validFrom)} - ${dateFormat.format(coupon.validUntil)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired
                            ? Colors.red
                            : (coupon.isActive ? Colors.green : Colors.blue),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onToggleActive,
                    icon: Icon(
                      coupon.isActive
                          ? Icons.pause_circle_outlined
                          : Icons.play_circle_outlined,
                      size: 18,
                    ),
                    label: Text(coupon.isActive ? 'Deactivate' : 'Activate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coupon.isActive
                          ? Colors.orange[700]
                          : AppColors.successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryOrange),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}

class _CreateCouponDialog extends StatefulWidget {
  final VoidCallback onCreate;

  const _CreateCouponDialog({required this.onCreate});

  @override
  State<_CreateCouponDialog> createState() => _CreateCouponDialogState();
}

class _CreateCouponDialogState extends State<_CreateCouponDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderController = TextEditingController(text: '0');
  final _maxDiscountController = TextEditingController();
  final _maxUsesController = TextEditingController();

  String _discountType = 'percentage';
  late DateTime _validFrom;
  late DateTime _validUntil;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Initialize dates to UTC to avoid timezone issues
    // Set validFrom to today at 00:00 UTC
    final now = DateTime.now().toUtc();
    _validFrom = DateTime.utc(now.year, now.month, now.day);
    // Set validUntil to 30 days from now at 23:59:59 UTC
    final futureDate = now.add(const Duration(days: 30));
    _validUntil = DateTime.utc(
        futureDate.year, futureDate.month, futureDate.day, 23, 59, 59);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _createCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final couponData = {
        'code': _codeController.text.toUpperCase().trim(),
        'description': _descriptionController.text.trim(),
        'discountType': _discountType,
        'discountValue': double.parse(_discountValueController.text),
        'minOrderValue': int.parse(_minOrderController.text),
        'maxDiscount': _maxDiscountController.text.isEmpty
            ? null
            : double.parse(_maxDiscountController.text),
        'maxUses': _maxUsesController.text.isEmpty
            ? null
            : int.parse(_maxUsesController.text),
        'validFrom': _validFrom.toIso8601String(),
        'validUntil': _validUntil.toIso8601String(),
      };

      final success =
          await context.read<CouponService>().createCoupon(couponData);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon created successfully!')),
        );
        widget.onCreate();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create coupon'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Coupon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Coupon Code
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Coupon Code',
                    prefixIcon: const Icon(Icons.local_offer),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter coupon code';
                    }
                    if (v.length < 3) {
                      return 'Code must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter description' : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Discount Type and Value
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _discountType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'percentage',
                            child: Text('% Discount'),
                          ),
                          DropdownMenuItem(
                            value: 'fixed',
                            child: Text('₹ Fixed'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _discountType = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _discountValueController,
                        decoration: InputDecoration(
                          labelText: 'Value',
                          prefixIcon:
                              Text(_discountType == 'percentage' ? '%' : '₹'),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Required'
                            : (double.tryParse(v) == null
                                ? 'Invalid number'
                                : null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Min Order & Max Discount
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minOrderController,
                        decoration: InputDecoration(
                          labelText: 'Min Order (₹)',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (double.tryParse(v ?? '0') == null
                            ? 'Invalid number'
                            : null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxDiscountController,
                        decoration: InputDecoration(
                          labelText: 'Max Discount (₹)',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Max Uses
                TextFormField(
                  controller: _maxUsesController,
                  decoration: InputDecoration(
                    labelText: 'Max Uses (Leave empty for unlimited)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Valid From & Until
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _validFrom,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            // Convert picked date to UTC at 00:00:00
                            setState(() => _validFrom = DateTime.utc(
                                picked.year, picked.month, picked.day));
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Valid From',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_validFrom),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _validUntil,
                            firstDate: _validFrom,
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            // Convert picked date to UTC at 23:59:59 (end of day)
                            setState(() => _validUntil = DateTime.utc(
                                picked.year,
                                picked.month,
                                picked.day,
                                23,
                                59,
                                59));
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Valid Until',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_validUntil),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Coupon',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditCouponDialog extends StatefulWidget {
  final Coupon coupon;
  final VoidCallback onUpdate;

  const _EditCouponDialog({
    required this.coupon,
    required this.onUpdate,
  });

  @override
  State<_EditCouponDialog> createState() => _EditCouponDialogState();
}

class _EditCouponDialogState extends State<_EditCouponDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _minOrderController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _maxUsesController;
  late DateTime _validFrom;
  late DateTime _validUntil;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.coupon.description);
    _discountValueController =
        TextEditingController(text: widget.coupon.discountValue.toString());
    _minOrderController =
        TextEditingController(text: widget.coupon.minOrderValue.toString());
    _maxDiscountController = TextEditingController(
        text: widget.coupon.maxDiscount?.toString() ?? '');
    _maxUsesController =
        TextEditingController(text: widget.coupon.maxUses?.toString() ?? '');
    _validFrom = widget.coupon.validFrom;
    _validUntil = widget.coupon.validUntil;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _updateCoupon() async {
    setState(() => _isUpdating = true);

    try {
      final updates = {
        'description': _descriptionController.text.trim(),
        'discountValue': double.parse(_discountValueController.text),
        'minOrderValue': int.parse(_minOrderController.text),
        'maxDiscount': _maxDiscountController.text.isEmpty
            ? null
            : double.parse(_maxDiscountController.text),
        'maxUses': _maxUsesController.text.isEmpty
            ? null
            : int.parse(_maxUsesController.text),
        'validFrom': _validFrom.toIso8601String(),
        'validUntil': _validUntil.toIso8601String(),
      };

      final success = await context
          .read<CouponService>()
          .updateCoupon(widget.coupon.id, updates);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon updated successfully!')),
        );
        widget.onUpdate();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update coupon'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Coupon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Code: ${widget.coupon.code}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Discount Value
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: 'Discount Value',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Min Order & Max Discount
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderController,
                      decoration: InputDecoration(
                        labelText: 'Min Order (₹)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxDiscountController,
                      decoration: InputDecoration(
                        labelText: 'Max Discount (₹)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Max Uses
              TextFormField(
                controller: _maxUsesController,
                decoration: InputDecoration(
                  labelText: 'Max Uses',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Valid From & Until
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _validFrom,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          // Convert picked date to UTC at 00:00:00
                          setState(() => _validFrom = DateTime.utc(
                              picked.year, picked.month, picked.day));
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Valid From',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_validFrom),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _validUntil,
                          firstDate: _validFrom,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          // Convert picked date to UTC at 23:59:59 (end of day)
                          setState(() => _validUntil = DateTime.utc(picked.year,
                              picked.month, picked.day, 23, 59, 59));
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Valid Until',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_validUntil),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Coupon',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
