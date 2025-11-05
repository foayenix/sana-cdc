import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/models/payment.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  PaymentStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(paymentsProvider.notifier).loadPayments();
      ref.read(paymentsProvider.notifier).loadSummary();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final paymentsState = ref.read(paymentsProvider);
    if (paymentsState.payments.length >= paymentsState.total) return;

    setState(() => _isLoadingMore = true);
    await ref.read(paymentsProvider.notifier).loadPayments(
          status: _selectedStatus,
          startDate: _startDate,
          endDate: _endDate,
          offset: paymentsState.payments.length,
        );
    setState(() => _isLoadingMore = false);
  }

  void _applyFilters() {
    ref.read(paymentsProvider.notifier).loadPayments(
          status: _selectedStatus,
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(paymentsProvider.notifier).refresh();
              ref.read(paymentsProvider.notifier).loadSummary();
            },
          ),
        ],
      ),
      body: paymentsState.isLoading && paymentsState.payments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : paymentsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${paymentsState.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(paymentsProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(paymentsProvider.notifier).refresh();
                    ref.read(paymentsProvider.notifier).loadSummary();
                  },
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (paymentsState.summary != null)
                        _buildSummaryCard(paymentsState.summary!),
                      const SizedBox(height: 16),
                      if (_selectedStatus != null ||
                          _startDate != null ||
                          _endDate != null)
                        _buildActiveFilters(),
                      const SizedBox(height: 8),
                      Text(
                        'Payments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (paymentsState.payments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No payments found'),
                          ),
                        )
                      else
                        ...paymentsState.payments.map(_buildPaymentCard),
                      if (_isLoadingMore)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(PaymentSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Spent',
                    PaymentService.formatAmount(summary.totalAmount),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Completed',
                    summary.completedCount.toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Refunded',
                    PaymentService.formatAmount(summary.totalRefunded),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pending',
                    summary.pendingCount.toString(),
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text('Active filters:'),
            if (_selectedStatus != null)
              Chip(
                label: Text(_selectedStatus!.name),
                onDeleted: () {
                  setState(() => _selectedStatus = null);
                  _applyFilters();
                },
              ),
            if (_startDate != null)
              Chip(
                label: Text('From: ${PaymentService.formatDate(_startDate!)}'),
                onDeleted: () {
                  setState(() => _startDate = null);
                  _applyFilters();
                },
              ),
            if (_endDate != null)
              Chip(
                label: Text('To: ${PaymentService.formatDate(_endDate!)}'),
                onDeleted: () {
                  setState(() => _endDate = null);
                  _applyFilters();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(payment.status),
          child: Icon(
            _getStatusIcon(payment.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          payment.practitioner?.practitionerProfile?.practiceName ??
              payment.practitioner?.name ??
              'Unknown Practitioner',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(payment.description ?? 'Payment'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  PaymentService.formatDate(payment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment.status.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getStatusColor(payment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              PaymentService.formatAmount(payment.amount, currency: payment.currency),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (payment.invoice != null)
              TextButton.icon(
                icon: const Icon(Icons.receipt, size: 14),
                label: const Text('Invoice', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  // TODO: Download/view invoice
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.COMPLETED:
        return Colors.green;
      case PaymentStatus.PENDING:
        return Colors.orange;
      case PaymentStatus.PROCESSING:
        return Colors.blue;
      case PaymentStatus.FAILED:
        return Colors.red;
      case PaymentStatus.REFUNDED:
        return Colors.purple;
      case PaymentStatus.CANCELLED:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.COMPLETED:
        return Icons.check_circle;
      case PaymentStatus.PENDING:
        return Icons.pending;
      case PaymentStatus.PROCESSING:
        return Icons.sync;
      case PaymentStatus.FAILED:
        return Icons.error;
      case PaymentStatus.REFUNDED:
        return Icons.undo;
      case PaymentStatus.CANCELLED:
        return Icons.cancel;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Payments'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status'),
              const SizedBox(height: 8),
              DropdownButtonFormField<PaymentStatus?>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...PaymentStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Date Range'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_startDate != null
                    ? 'From: ${PaymentService.formatDate(_startDate!)}'
                    : 'Select Start Date'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_endDate != null
                    ? 'To: ${PaymentService.formatDate(_endDate!)}'
                    : 'Select End Date'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
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
                    'Payment Details',
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
                    _buildDetailRow('Amount', PaymentService.formatAmount(payment.amount, currency: payment.currency)),
                    _buildDetailRow('Status', payment.status.name),
                    _buildDetailRow('Method', payment.method.name),
                    _buildDetailRow('Date', PaymentService.formatDateTime(payment.createdAt)),
                    if (payment.completedAt != null)
                      _buildDetailRow('Completed', PaymentService.formatDateTime(payment.completedAt!)),
                    _buildDetailRow('Practitioner', payment.practitioner?.name ?? 'Unknown'),
                    if (payment.description != null)
                      _buildDetailRow('Description', payment.description!),
                    if (payment.refundedAmount != null && payment.refundedAmount! > 0) ...[
                      const Divider(),
                      Text(
                        'Refund Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Refunded Amount', PaymentService.formatAmount(payment.refundedAmount!)),
                      if (payment.refundedAt != null)
                        _buildDetailRow('Refunded At', PaymentService.formatDateTime(payment.refundedAt!)),
                      if (payment.refundReason != null)
                        _buildDetailRow('Reason', payment.refundReason!),
                    ],
                    if (payment.invoice != null) ...[
                      const Divider(),
                      Text(
                        'Invoice',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Invoice Number', payment.invoice!.invoiceNumber),
                      _buildDetailRow('Invoice Status', payment.invoice!.status.name),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download Invoice'),
                        onPressed: () {
                          // TODO: Download invoice PDF
                        },
                      ),
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
