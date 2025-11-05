import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sana_app/core/constants/app_constants.dart';
import 'package:sana_app/core/theme/app_colors.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/presentation/providers/auth_provider.dart';
import 'package:sana_app/presentation/providers/health_score_provider.dart';
import 'package:sana_app/presentation/widgets/health_score_gauge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final healthScoreAsync = ref.watch(healthScoreProvider);
    final topLeversAsync = ref.watch(topLeversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(healthScoreProvider);
          ref.invalidate(topLeversProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome back, ${user?.name ?? ""}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Health Score Card
              healthScoreAsync.when(
                data: (scoreData) {
                  if (!scoreData.completed) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.health_and_safety_outlined,
                                size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'Complete your health questionnaire',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Get personalized insights about your wellness',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.push(AppConstants.routeQuestionnaire);
                              },
                              child: const Text('Start Questionnaire'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Your SANA Health Score',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          HealthScoreGauge(
                            score: scoreData.currentScore ?? 0,
                            status: scoreData.currentStatus ?? 'BALANCED',
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _getStatusMessage(scoreData.currentStatus ?? ''),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: LoadingIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: CustomErrorWidget(
                      message: error.toString(),
                      onRetry: () {
                        ref.invalidate(healthScoreProvider);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Domain Scores
              healthScoreAsync.whenData((scoreData) {
                if (!scoreData.completed || scoreData.domainScores == null) {
                  return const SizedBox();
                }

                final domains = scoreData.domainScores!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Wellness Domains',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _DomainCard(
                          title: 'Physical',
                          score: domains['physical'] ?? 0,
                          maxScore: 25,
                          color: AppColors.physicalDomain,
                        ),
                        _DomainCard(
                          title: 'Mental',
                          score: domains['mental'] ?? 0,
                          maxScore: 25,
                          color: AppColors.mentalDomain,
                        ),
                        _DomainCard(
                          title: 'Lifestyle',
                          score: domains['lifestyle'] ?? 0,
                          maxScore: 25,
                          color: AppColors.lifestyleDomain,
                        ),
                        _DomainCard(
                          title: 'Social',
                          score: domains['social'] ?? 0,
                          maxScore: 25,
                          color: AppColors.socialDomain,
                        ),
                      ],
                    ),
                  ],
                );
              }).data ?? const SizedBox(),

              const SizedBox(height: 24),

              // Top Wellness Levers
              topLeversAsync.when(
                data: (levers) {
                  if (levers.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Top 3 Wellness Levers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...levers.map((lever) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up,
                                    color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(lever),
                                ),
                              ],
                            ),
                          )),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 24),

              // Daily Check-in Card
              Card(
                color: AppColors.primary.withOpacity(0.1),
                child: InkWell(
                  onTap: () {
                    context.push(AppConstants.routeCheckin);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Check-In',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quick! How are you feeling today?',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.search,
                      title: 'Find Practitioner',
                      onTap: () {
                        context.push(AppConstants.routePractitioners);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.book_outlined,
                      title: 'Journal',
                      onTap: () {
                        context.push(AppConstants.routeJournal);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.lightbulb_outline,
                      title: 'Recommendations',
                      onTap: () {
                        context.push(AppConstants.routeRecommendations);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Appointments',
                      onTap: () {
                        context.push(AppConstants.routeAppointments);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'RADIANT':
        return 'Amazing! You\'re at your wellness peak!';
      case 'THRIVING':
        return 'Great! You\'re doing really well!';
      case 'BALANCED':
        return 'Good! You\'re maintaining a healthy balance.';
      case 'REBUILDING':
        return 'You\'re making progress. Keep going!';
      case 'NEEDS_SUPPORT':
        return 'Consider reaching out to a practitioner for support.';
      default:
        return '';
    }
  }
}

class _DomainCard extends StatelessWidget {
  final String title;
  final int score;
  final int maxScore;
  final Color color;

  const _DomainCard({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / maxScore * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$score/$maxScore',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: score / maxScore,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 4),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
