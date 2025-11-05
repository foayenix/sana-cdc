import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/models/payment.dart';

class PayoutDashboardScreen extends ConsumerStatefulWidget {
  const PayoutDashboardScreen({super.key});

  @override
  ConsumerState<PayoutDashboardScreen> createState() =>
      _PayoutDashboardScreenState();
}

class _PayoutDashboardScreenState extends ConsumerState<PayoutDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(payoutsProvider.notifier).loadPayouts();
      ref.read(payoutsProvider.notifier).loadSummary();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final payoutsState = ref.read(payoutsProvider);
    if (payoutsState.payouts.length >= payoutsState.total) return;

    setState(() => _isLoadingMore = true);
    await ref.read(payoutsProvider.notifier).loadPayouts(
          offset: payoutsState.payouts.length,
        );
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final payoutsState = ref.watch(payoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Payouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(payoutsProvider.notifier).refresh();
              ref.read(payoutsProvider.notifier).loadSummary();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Payout History'),
          ],
        ),
      ),
      body: payoutsState.isLoading && payoutsState.payouts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : payoutsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${payoutsState.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(payoutsProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(payoutsState),
                    _buildPayoutHistoryTab(payoutsState),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab(PayoutsState state) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(payoutsProvider.notifier).refresh();
        ref.read(payoutsProvider.notifier).loadSummary();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.summary != null) ...[
            _buildSummaryCard(state.summary!),
            const SizedBox(height: 16),
            _buildEarningsBreakdown(state.summary!),
            const SizedBox(height: 16),
            _buildUpcomingPayout(state.summary!),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PayoutSummary summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Earnings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              PaymentService.formatAmount(summary.totalAmount),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed Payouts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.totalPayouts.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        PaymentService.formatAmount(summary.pendingAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(PayoutSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildBreakdownRow(
              'Total Earned',
              PaymentService.formatAmount(summary.totalAmount),
              Colors.green,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Paid Out',
              PaymentService.formatAmount(summary.completedAmount),
              Colors.blue,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Pending Payout',
              PaymentService.formatAmount(summary.pendingAmount),
              Colors.orange,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Unpaid Payments (${summary.unpaidPaymentsCount})',
              PaymentService.formatAmount(summary.unpaidPaymentsAmount),
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPayout(PayoutSummary summary) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Next Payout',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Scheduled for: ${summary.nextPayoutDate != null ? PaymentService.formatDate(summary.nextPayoutDate!) : 'TBD'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Estimated amount: ${PaymentService.formatAmount(summary.unpaidPaymentsAmount)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.unpaidPaymentsCount} unpaid payment(s) will be included',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutHistoryTab(PayoutsState state) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(payoutsProvider.notifier).refresh();
      },
      child: state.payouts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No payouts yet'),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.payouts.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.payouts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final payout = state.payouts[index];
                return _buildPayoutCard(payout);
              },
            ),
    );
  }

  Widget _buildPayoutCard(Payout payout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPayoutStatusColor(payout.status),
          child: Icon(
            _getPayoutStatusIcon(payout.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          PaymentService.formatAmount(payout.amount, currency: payout.currency),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${PaymentService.formatDate(payout.periodStart)} - ${PaymentService.formatDate(payout.periodEnd)}',
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPayoutStatusColor(payout.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payout.status.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getPayoutStatusColor(payout.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${payout.paymentCount} payment(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showPayoutDetails(payout),
      ),
    );
  }

  Color _getPayoutStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.COMPLETED:
        return Colors.green;
      case PayoutStatus.PENDING:
        return Colors.orange;
      case PayoutStatus.PROCESSING:
        return Colors.blue;
      case PayoutStatus.FAILED:
        return Colors.red;
    }
  }

  IconData _getPayoutStatusIcon(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.COMPLETED:
        return Icons.check_circle;
      case PayoutStatus.PENDING:
        return Icons.pending;
      case PayoutStatus.PROCESSING:
        return Icons.sync;
      case PayoutStatus.FAILED:
        return Icons.error;
    }
  }

  void _showPayoutDetails(Payout payout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Payout Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow(
                      'Amount',
                      PaymentService.formatAmount(payout.amount, currency: payout.currency),
                    ),
                    _buildDetailRow('Status', payout.status.name),
                    _buildDetailRow('Payment Count', payout.paymentCount.toString()),
                    _buildDetailRow(
                      'Period',
                      '${PaymentService.formatDate(payout.periodStart)} - ${PaymentService.formatDate(payout.periodEnd)}',
                    ),
                    _buildDetailRow(
                      'Created',
                      PaymentService.formatDateTime(payout.createdAt),
                    ),
                    if (payout.completedAt != null)
                      _buildDetailRow(
                        'Completed',
                        PaymentService.formatDateTime(payout.completedAt!),
                      ),
                    if (payout.scheduledFor != null)
                      _buildDetailRow(
                        'Scheduled For',
                        PaymentService.formatDateTime(payout.scheduledFor!),
                      ),
                    if (payout.description != null)
                      _buildDetailRow('Description', payout.description!),
                    if (payout.failureReason != null) ...[
                      const Divider(),
                      Text(
                        'Failure Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Reason', payout.failureReason!),
                    ],
                    if (payout.payments != null && payout.payments!.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Included Payments (${payout.payments!.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...payout.payments!.map((payment) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                PaymentService.formatAmount(payment.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                payment.client?.name ?? 'Unknown Client',
                              ),
                              trailing: Text(
                                PaymentService.formatDate(payment.createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
