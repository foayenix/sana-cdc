import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/data/services/analytics_service.dart';
import 'package:sana_app/data/models/analytics.dart';

class ClientAnalyticsScreen extends ConsumerStatefulWidget {
  const ClientAnalyticsScreen({super.key});

  @override
  ConsumerState<ClientAnalyticsScreen> createState() =>
      _ClientAnalyticsScreenState();
}

class _ClientAnalyticsScreenState extends ConsumerState<ClientAnalyticsScreen> {
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
      clientAnalyticsProvider((startDate: _startDate, endDate: _endDate)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Analytics'),
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
                  ref.invalidate(clientAnalyticsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context, ClientAnalytics analytics) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientAnalyticsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateRangeCard(analytics.dateRange),
          const SizedBox(height: 16),
          _buildOverviewSection(analytics.overview),
          const SizedBox(height: 24),
          if (analytics.sanaIndexProgression.isNotEmpty) ...[
            _buildSectionHeader('SANA Index Progression'),
            const SizedBox(height: 12),
            _buildSanaIndexChart(analytics.sanaIndexProgression),
            const SizedBox(height: 24),
          ],
          if (analytics.monthlyTrend.isNotEmpty) ...[
            _buildSectionHeader('Appointment Trend'),
            const SizedBox(height: 12),
            _buildMonthlyTrendChart(analytics.monthlyTrend),
            const SizedBox(height: 24),
          ],
          if (analytics.sessionTypeDistribution.isNotEmpty) ...[
            _buildSectionHeader('Session Types'),
            const SizedBox(height: 12),
            _buildSessionTypeDistribution(analytics.sessionTypeDistribution),
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
              dateFormat.format(dateRange.startDate) + ' - ' + dateFormat.format(dateRange.endDate),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ClientAnalyticsOverview overview) {
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
                'Total Spent',
                '£' + overview.totalSpent.toStringAsFixed(2),
                Icons.payments,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Outcome',
                overview.averageOutcomeScore > 0
                    ? overview.averageOutcomeScore.toStringAsFixed(1)
                    : 'N/A',
                Icons.stars,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Current SANA Index',
          overview.currentSanaIndex.toStringAsFixed(1),
          Icons.favorite,
          Colors.pink,
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

  Widget _buildSanaIndexChart(List<SanaIndexDataPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
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
                        final date = data[value.toInt()].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM dd').format(date),
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.score))
                      .toList(),
                  isCurved: true,
                  color: Colors.pink,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.pink.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<MonthlyTrendDataPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
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
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          toY: e.value.count.toDouble(),
                          color: Colors.blue,
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
                      item.count.toString() + ' (' + item.percentage.toStringAsFixed(1) + '%)',
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
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 90)),
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
