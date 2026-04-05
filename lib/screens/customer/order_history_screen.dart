import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../models/order.dart';
import '../../utils/app_colors.dart';
import 'login_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _ordersFuture = OrderService.getCustomerOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Please login to view your orders',
                style: TextStyle(fontSize: 18, color: AppColors.textGrey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              icon: const Icon(Icons.login),
              label: const Text('Login'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.primaryOrange,
      child: FutureBuilder<List<Order>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No orders yet',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Place your first order to see it here!',
                    style: TextStyle(color: AppColors.textGrey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        );
      },
    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final statusColor = AppColors.getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(14),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long, color: statusColor, size: 24),
        ),
        title: Text(
          'Order #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateFormat.format(order.orderDate),
                style:
                    const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            const SizedBox(height: 3),
            Text(
              '${order.items.length} item(s) • ₹${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
              ),
            ),
          ],
        ),
        children: [
          // Status progress bar
          _StatusProgress(status: order.status),
          const SizedBox(height: 14),

          // Items
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Items Ordered',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.foodItemName,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Text('${item.quantity}x',
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(
                      '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                          fontSize: 13),
                    ),
                  ],
                ),
              )),

          const Divider(height: 20),

          // Delivery info
          _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: order.deliveryAddress),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: order.phoneNumber),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.payment_outlined,
              label: 'Payment',
              value: order.paymentMethod == 'Cash'
                  ? 'Cash on Delivery'
                  : 'Online Payment'),

          // Review button (only for delivered orders)
          if (order.status == 'Delivered') ...[
            const SizedBox(height: 14),
            FutureBuilder<bool>(
              future: ReviewService.hasReviewed(order.id),
              builder: (context, snapshot) {
                final hasReviewed = snapshot.data ?? false;
                if (hasReviewed) {
                  return const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.successGreen, size: 18),
                      SizedBox(width: 6),
                      Text('You\'ve reviewed this order',
                          style: TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w500)),
                    ],
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewDialog(context, order.id),
                    icon: const Icon(Icons.star_outline,
                        color: AppColors.primaryOrange),
                    label: const Text('Rate & Review',
                        style: TextStyle(color: AppColors.primaryOrange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryOrange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String orderId) {
    double rating = 4;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate Your Experience',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your food?',
                  style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 36,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (r) {
                  setDialogState(() => rating = r);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await ReviewService.submitReview(
                  orderId: orderId,
                  rating: rating,
                  comment: commentController.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['success']
                      ? 'Thank you for your review! 🌟'
                      : result['error']),
                  backgroundColor: result['success']
                      ? AppColors.successGreen
                      : AppColors.errorRed,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusProgress extends StatelessWidget {
  final String status;
  const _StatusProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['Pending', 'Preparing', 'Ready', 'Delivered'];
    final currentIdx = steps.indexOf(status);
    if (status == 'Cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.errorRed, size: 20),
            SizedBox(width: 8),
            Text('Order Cancelled',
                style: TextStyle(
                    color: AppColors.errorRed, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIdx < currentIdx
                    ? AppColors.successGreen
                    : Colors.grey[300],
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isCompleted = stepIdx <= currentIdx;
          return Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      isCompleted ? AppColors.successGreen : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(steps[stepIdx],
                  style: TextStyle(
                      fontSize: 9,
                      color: isCompleted
                          ? AppColors.successGreen
                          : AppColors.textGrey,
                      fontWeight:
                          isCompleted ? FontWeight.bold : FontWeight.normal)),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryOrange),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ),
      ],
    );
  }
}
