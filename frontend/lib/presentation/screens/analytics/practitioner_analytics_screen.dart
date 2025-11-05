import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/data/services/analytics_service.dart';
import 'package:sana_app/data/models/analytics.dart';

class PractitionerAnalyticsScreen extends ConsumerStatefulWidget {
  const PractitionerAnalyticsScreen({super.key});

  @override
  ConsumerState<PractitionerAnalyticsScreen> createState() =>
      _PractitionerAnalyticsScreenState();
}

class _PractitionerAnalyticsScreenState
    extends ConsumerState<PractitionerAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 90));
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(
      practitionerAnalyticsProvider(
          (startDate: _startDate, endDate: _endDate)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Change date range',
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _buildAnalytics(context, analytics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(practitionerAnalyticsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalytics(
      BuildContext context, PractitionerAnalytics analytics) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(practitionerAnalyticsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateRangeCard(analytics.dateRange),
          const SizedBox(height: 16),
          _buildOverviewSection(analytics.overview),
          const SizedBox(height: 24),
          if (analytics.monthlyRevenue.isNotEmpty) ...[
            _buildSectionHeader('Monthly Revenue'),
            const SizedBox(height: 12),
            _buildMonthlyRevenueChart(analytics.monthlyRevenue),
            const SizedBox(height: 24),
          ],
          if (analytics.sessionTypeDistribution.isNotEmpty) ...[
            _buildSectionHeader('Session Types'),
            const SizedBox(height: 12),
            _buildSessionTypeDistribution(analytics.sessionTypeDistribution),
            const SizedBox(height: 24),
          ],
          if (analytics.topClients.isNotEmpty) ...[
            _buildSectionHeader('Top Clients'),
            const SizedBox(height: 12),
            _buildTopClients(analytics.topClients),
            const SizedBox(height: 24),
          ],
          if (analytics.upcomingAppointments.isNotEmpty) ...[
            _buildSectionHeader('Upcoming Appointments'),
            const SizedBox(height: 12),
            _buildUpcomingAppointments(analytics.upcomingAppointments),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRangeCard(DateRange dateRange) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(dateRange.startDate) +
                  ' - ' +
                  dateFormat.format(dateRange.endDate),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(PractitionerAnalyticsOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Appointments',
                overview.totalAppointments.toString(),
                Icons.calendar_month,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                overview.completedAppointments.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Upcoming',
                overview.upcomingAppointments.toString(),
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cancelled',
                overview.cancelledAppointments.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Earnings',
                '£' + overview.totalEarnings.toStringAsFixed(2),
                Icons.attach_money,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Clients',
                overview.totalClients.toString(),
                Icons.people,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Repeat Client Rate',
          overview.repeatClientRate.toStringAsFixed(1) + '%',
          Icons.repeat,
          Colors.amber,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: fullWidth
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: fullWidth ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildMonthlyRevenueChart(List<MonthlyRevenueDataPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '£' + value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < data.length) {
                        final month = data[value.toInt()].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            month.substring(5),
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              barGroups: data
                  .asMap()
                  .entries
                  .map(
                    (e) => BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.revenue,
                          color: Colors.green,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTypeDistribution(
      List<SessionTypeDistribution> distribution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: distribution
                      .asMap()
                      .entries
                      .map(
                        (e) => PieChartSectionData(
                          value: e.value.count.toDouble(),
                          title: e.value.percentage.toStringAsFixed(0) + '%',
                          color: _getColorForIndex(e.key),
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                      .toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.map((item) {
              final index = distribution.indexOf(item);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getColorForIndex(index),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      item.count.toString() +
                          ' (' +
                          item.percentage.toStringAsFixed(1) +
                          '%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClients(List<TopClient> clients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: clients
              .map(
                (client) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      client.clientName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(client.clientName),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      client.appointmentCount.toString() + ' sessions',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments(
      List<UpcomingAppointmentSummary> appointments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: appointments
              .map(
                (appt) => ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event, color: Colors.orange),
                  ),
                  title: Text(appt.clientName),
                  subtitle: Text(appt.sessionType),
                  trailing: Text(
                    DateFormat('MMM dd, HH:mm').format(appt.appointmentDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start:
            _startDate ?? DateTime.now().subtract(const Duration(days: 90)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }
}
