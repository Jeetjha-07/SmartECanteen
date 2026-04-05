import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../utils/app_colors.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.restaurantPrimary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryOrange,
            labelColor: AppColors.primaryOrange,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Active Orders', icon: Icon(Icons.pending_actions)),
              Tab(text: 'All Orders', icon: Icon(Icons.history)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ActiveOrdersTab(),
              _AllOrdersTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primaryOrange,
      child: StreamBuilder<List<Order>>(
        stream: OrderService.getActiveOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: AppColors.successGreen, size: 56),
                    ),
                    const SizedBox(height: 16),
                    const Text('All caught up!',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('No active orders at the moment',
                        style: TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                _RestaurantOrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _AllOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primaryOrange,
      child: StreamBuilder<List<Order>>(
        stream: OrderService.getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Text('No orders yet',
                    style: TextStyle(color: AppColors.textGrey)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                _RestaurantOrderCard(order: orders[index], compact: true),
          );
        },
      ),
    );
  }
}

class _RestaurantOrderCard extends StatefulWidget {
  final Order order;
  final bool compact;
  const _RestaurantOrderCard({required this.order, this.compact = false});

  @override
  State<_RestaurantOrderCard> createState() => _RestaurantOrderCardState();
}

class _RestaurantOrderCardState extends State<_RestaurantOrderCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final success =
        await OrderService.updateOrderStatus(widget.order.id, newStatus);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Order status updated to $newStatus'
          : 'Failed to update status'),
      backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
              child: const Text('Cancel Order')),
        ],
      ),
    );
    if (confirm == true) _updateStatus('Cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = AppColors.getStatusColor(order.status);
    final dateFormat = DateFormat('MMM dd • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '#${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)} • ${dateFormat.format(order.orderDate)}',
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(order.status,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primaryOrange),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('${item.quantity}x ',
                              style: const TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Expanded(
                              child: Text(item.foodItemName,
                                  style: const TextStyle(fontSize: 13))),
                          Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textGrey)),
                        ],
                      ),
                    )),

                const Divider(height: 16),

                // Delivery info
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(order.deliveryAddress,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(order.phoneNumber,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),

                // Action buttons
                if (!order.isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (order.nextStatus != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUpdating
                                ? null
                                : () => _updateStatus(order.nextStatus!),
                            icon: _isUpdating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Icon(_getNextStatusIcon(order.nextStatus!)),
                            label: Text('Mark as ${order.nextStatus}'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      if (order.nextStatus != null) const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isUpdating ? null : _cancelOrder,
                        icon: const Icon(Icons.cancel_outlined,
                            color: AppColors.errorRed, size: 16),
                        label: const Text('Cancel',
                            style: TextStyle(color: AppColors.errorRed)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.errorRed),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNextStatusIcon(String status) {
    switch (status) {
      case 'Preparing':
        return Icons.soup_kitchen_outlined;
      case 'Ready':
        return Icons.check_circle_outline;
      case 'Delivered':
        return Icons.delivery_dining;
      default:
        return Icons.arrow_forward;
    }
  }
}
