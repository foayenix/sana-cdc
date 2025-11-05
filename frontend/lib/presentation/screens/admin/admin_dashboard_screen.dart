import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/admin_service.dart';
import '../../../core/constants/app_constants.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(platformStatsProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(platformStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(platformStatsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: statsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : statsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${statsState.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(platformStatsProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(platformStatsProvider.notifier).refresh();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Statistics',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (statsState.stats != null)
                          _buildStatsGrid(statsState.stats!),
                        const SizedBox(height: 32),
                        Text(
                          'Management',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCards(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsGrid(stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Users',
          stats.totalUsers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Clients',
          stats.totalClients.toString(),
          Icons.person,
          Colors.green,
        ),
        _buildStatCard(
          'Practitioners',
          stats.totalPractitioners.toString(),
          Icons.medical_services,
          Colors.purple,
        ),
        _buildStatCard(
          'Appointments',
          stats.totalAppointments.toString(),
          Icons.calendar_today,
          Colors.orange,
        ),
        _buildStatCard(
          'Total Revenue',
          '\$${stats.totalRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.teal,
        ),
        _buildStatCard(
          'Pending Verifications',
          stats.pendingVerifications.toString(),
          Icons.pending_actions,
          Colors.red,
        ),
        _buildStatCard(
          'Active Conversations',
          stats.activeConversations.toString(),
          Icons.chat,
          Colors.indigo,
        ),
        _buildStatCard(
          'Total Reviews',
          stats.totalReviews.toString(),
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCards() {
    return Column(
      children: [
        _buildManagementCard(
          'User Management',
          'View and manage all users on the platform',
          Icons.people_outline,
          Colors.blue,
          () {
            context.push(AppConstants.routeAdminUsers);
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          'Practitioner Verification',
          'Review pending practitioner verifications',
          Icons.verified_user,
          Colors.green,
          () {
            context.push(AppConstants.routeAdminVerifications);
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          'Review Moderation',
          'Moderate and manage user reviews',
          Icons.rate_review,
          Colors.orange,
          () {
            context.push(AppConstants.routeAdminReviews);
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          'Appointments',
          'View and manage appointments',
          Icons.calendar_month,
          Colors.purple,
          () {
            context.push(AppConstants.routeAdminAppointments);
          },
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
