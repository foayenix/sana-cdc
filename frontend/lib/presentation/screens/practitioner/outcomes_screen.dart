import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/models/appointment.dart';
import 'package:sana_app/data/models/outcome.dart';
import 'package:sana_app/data/services/appointments_service.dart';
import 'package:sana_app/data/services/outcomes_service.dart';

// Providers
final outcomesProvider = FutureProvider.autoDispose<List<Outcome>>(
  (ref) async {
    final service = ref.watch(outcomesServiceProvider);
    return await service.getOutcomes();
  },
);

final outcomeStatsProvider = FutureProvider.autoDispose<OutcomeStatistics>(
  (ref) async {
    final service = ref.watch(outcomesServiceProvider);
    return await service.getOutcomeStatistics();
  },
);

class OutcomesScreen extends ConsumerWidget {
  const OutcomesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcomesAsync = ref.watch(outcomesProvider);
    final statsAsync = ref.watch(outcomeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Outcomes'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(outcomesProvider);
          ref.invalidate(outcomeStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            statsAsync.when(
              data: (stats) => _buildStatisticsCard(context, stats),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Outcomes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            outcomesAsync.when(
              data: (outcomes) {
                if (outcomes.isEmpty) {
                  return _buildEmptyState(context);
                }
                return Column(
                  children: outcomes
                      .map((outcome) => _buildOutcomeCard(context, outcome))
                      .toList(),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => CustomErrorWidget(
                message: error.toString(),
                onRetry: () => ref.invalidate(outcomesProvider),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOutcomeDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Record Outcome'),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, OutcomeStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outcomes Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Outcomes',
                    stats.totalOutcomes.toString(),
                    Icons.assessment,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Average Score',
                    stats.averageScore.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Score Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: stats.distribution.values.isEmpty
                      ? 10
                      : stats.distribution.values
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble() +
                          2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}⭐',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [1, 2, 3, 4, 5].map((score) {
                    final count = stats.distribution[score.toString()] ?? 0;
                    return BarChartGroupData(
                      x: score,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: _getScoreColor(score),
                          width: 30,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No outcomes recorded yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record outcomes after completed sessions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeCard(BuildContext context, Outcome outcome) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getScoreColor(outcome.outcomeScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        outcome.outcomeScore.toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(outcome.outcomeScore),
                        ),
                      ),
                      Text(
                        '/5',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getScoreLabel(outcome.outcomeScore),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        DateFormat('MMMM d, y').format(outcome.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (outcome.improvementNotes != null) ...[
              const SizedBox(height: 12),
              Text(
                'Improvement Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(outcome.improvementNotes!),
            ],
            if (outcome.goalsAchieved.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Goals Achieved',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: outcome.goalsAchieved.map((goal) {
                  return Chip(
                    label: Text(goal),
                    avatar: const Icon(Icons.check_circle, size: 16),
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            if (outcome.nextSteps != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Steps',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(outcome.nextSteps!, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getScoreLabel(int score) {
    switch (score) {
      case 5:
        return 'Excellent Progress';
      case 4:
        return 'Good Progress';
      case 3:
        return 'Moderate Progress';
      case 2:
        return 'Slight Progress';
      case 1:
        return 'No Progress';
      default:
        return 'Unknown';
    }
  }

  Future<void> _showCreateOutcomeDialog(BuildContext context, WidgetRef ref) async {
    final completedAppointments = await ref.read(completedAppointmentsProvider.future);

    if (completedAppointments.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No completed appointments to record outcomes for'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CreateOutcomeScreen(appointments: completedAppointments),
        ),
      );

      ref.invalidate(outcomesProvider);
      ref.invalidate(outcomeStatsProvider);
    }
  }
}

// Create Outcome Screen
class CreateOutcomeScreen extends ConsumerStatefulWidget {
  final List<Appointment> appointments;

  const CreateOutcomeScreen({super.key, required this.appointments});

  @override
  ConsumerState<CreateOutcomeScreen> createState() =>
      _CreateOutcomeScreenState();
}

class _CreateOutcomeScreenState extends ConsumerState<CreateOutcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  Appointment? selectedAppointment;
  int outcomeScore = 3;
  final improvementNotesController = TextEditingController();
  final goalsController = TextEditingController();
  List<String> goalsAchieved = [];
  final nextStepsController = TextEditingController();
  bool isSaving = false;

  @override
  void dispose() {
    improvementNotesController.dispose();
    goalsController.dispose();
    nextStepsController.dispose();
    super.dispose();
  }

  Future<void> _saveOutcome() async {
    if (!_formKey.currentState!.validate() || selectedAppointment == null) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final service = ref.read(outcomesServiceProvider);
      await service.createOutcome(
        appointmentId: selectedAppointment!.id,
        outcomeScore: outcomeScore,
        improvementNotes: improvementNotesController.text.trim().isNotEmpty
            ? improvementNotesController.text.trim()
            : null,
        goalsAchieved: goalsAchieved,
        nextSteps: nextStepsController.text.trim().isNotEmpty
            ? nextStepsController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outcome recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record outcome: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Client Outcome'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Select Appointment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Appointment>(
              value: selectedAppointment,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose an appointment',
              ),
              items: widget.appointments.map((apt) {
                return DropdownMenuItem(
                  value: apt,
                  child: Text(
                    '${apt.client?.user.name ?? "Client"} - ${DateFormat("MMM d, y").format(apt.appointmentDate)}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedAppointment = value);
              },
              validator: (value) =>
                  value == null ? 'Please select an appointment' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Outcome Score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 5].map((score) {
                return GestureDetector(
                  onTap: () => setState(() => outcomeScore = score),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: outcomeScore == score
                          ? _getScoreColor(score)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: outcomeScore == score
                            ? _getScoreColor(score)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        score.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              outcomeScore == score ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getScoreLabel(outcomeScore),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Improvement Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: improvementNotesController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe the client\'s progress and improvements...',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Goals Achieved',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: goalsController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add a goal',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (goalsController.text.trim().isNotEmpty) {
                      setState(() {
                        goalsAchieved.add(goalsController.text.trim());
                        goalsController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (goalsAchieved.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: goalsAchieved.map((goal) {
                  return Chip(
                    label: Text(goal),
                    onDeleted: () {
                      setState(() => goalsAchieved.remove(goal));
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Next Steps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: nextStepsController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Recommended next steps for the client...',
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: isSaving ? 'Saving...' : 'Record Outcome',
              onPressed: isSaving ? null : _saveOutcome,
              isLoading: isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getScoreLabel(int score) {
    switch (score) {
      case 5:
        return 'Excellent Progress';
      case 4:
        return 'Good Progress';
      case 3:
        return 'Moderate Progress';
      case 2:
        return 'Slight Progress';
      case 1:
        return 'No Progress';
      default:
        return 'Unknown';
    }
  }
}
