import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class RestaurantAnalyticsScreen extends StatefulWidget {
  const RestaurantAnalyticsScreen({super.key});

  @override
  State<RestaurantAnalyticsScreen> createState() =>
      _RestaurantAnalyticsScreenState();
}

class _RestaurantAnalyticsScreenState extends State<RestaurantAnalyticsScreen> {
  late Future<Map<String, dynamic>> _analyticsData;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final user = AuthService.currentUser;
    print('📊 Analytics Screen: Loading analytics');
    print('   User email: ${user?.email}');
    print('   User restaurantId: ${user?.restaurantId}');

    if (user?.restaurantId == null) {
      // Show error if no restaurant ID
      print('❌ Analytics Screen: No restaurantId found!');
      _analyticsData =
          Future.value({'error': 'Restaurant information not available'});
    } else {
      print('✅ Analytics Screen: Using restaurantId: ${user!.restaurantId}');
      _analyticsData = AnalyticsService.getBasicAnalytics(user!.restaurantId!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...',
                      style: TextStyle(color: AppColors.textGrey)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.errorRed, size: 48),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadAnalytics,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          if (data.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No analytics data available yet'),
              ),
            );
          }

          // Extract analytics data
          final totalRevenue = (data['totalRevenue'] ?? 0.0) as double;
          final totalOrders = (data['totalOrders'] ?? 0) as int;
          final avgOrderValue = (data['avgOrderValue'] ?? 0.0) as double;
          final avgRating = (data['avgRating'] ?? 0.0) as double;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Banner
                _SummaryBanner(
                  totalRevenue: totalRevenue,
                  totalOrders: totalOrders,
                ),
                const SizedBox(height: 24),

                // KPI Cards
                const Text('Key Metrics',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _KpiGrid(
                  totalRevenue: totalRevenue,
                  totalOrders: totalOrders,
                  avgOrderValue: avgOrderValue,
                  avgRating: avgRating,
                ),
                const SizedBox(height: 24),

                // Quick Stats
                const Text('Quick Statistics',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _QuickStats(data: data),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;

  const _SummaryBanner({
    required this.totalRevenue,
    required this.totalOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.restaurantPrimary, Color(0xFF2D4A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Restaurant Overview',
              style: TextStyle(
                  color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Revenue',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('₹${totalRevenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Orders',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('$totalOrders',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final double avgRating;

  const _KpiGrid({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _KpiCard(
          label: 'Avg Order Value',
          value: '₹${avgOrderValue.toStringAsFixed(0)}',
          icon: Icons.shopping_cart_outlined,
          color: AppColors.primaryOrange,
        ),
        _KpiCard(
          label: 'Avg Rating',
          value: '${avgRating.toStringAsFixed(1)} ⭐',
          icon: Icons.star_outline,
          color: Colors.amber,
        ),
        _KpiCard(
          label: 'Total Orders',
          value: '$totalOrders',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.successGreen,
        ),
        _KpiCard(
          label: 'Revenue',
          value: '₹${totalRevenue.toStringAsFixed(0)}',
          icon: Icons.currency_rupee,
          color: AppColors.darkGreen,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final Map<String, dynamic> data;

  const _QuickStats({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'Top Category',
            value: data['topCategory'] ?? 'N/A',
            icon: Icons.category_outlined,
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Total Reviews',
            value: '${data['totalReviews'] ?? 0}',
            icon: Icons.rate_review_outlined,
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Active Orders',
            value: '${data['activeOrders'] ?? 0}',
            icon: Icons.local_shipping_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textGrey, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textDark)),
          ],
        ),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
