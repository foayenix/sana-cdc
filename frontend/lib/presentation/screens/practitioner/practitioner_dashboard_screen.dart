import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/services/sana_index_service.dart';
import 'package:sana_app/data/services/practitioners_service.dart';

final practitionerProfileProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(practitionersServiceProvider);
  return await service.getProfile();
});

final sanaIndexProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(sanaIndexServiceProvider);
  return await service.getMyIndex();
});

class PractitionerDashboardScreen extends ConsumerWidget {
  const PractitionerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(practitionerProfileProvider);
    final sanaIndexAsync = ref.watch(sanaIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practitioner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/practitioner/profile-setup'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(practitionerProfileProvider);
            ref.invalidate(sanaIndexProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Verification Status Card
                _buildVerificationStatusCard(context, profile.verificationStatus),
                const SizedBox(height: 16),

                // SANA Index Card
                sanaIndexAsync.when(
                  data: (sanaIndex) => _buildSanaIndexCard(context, sanaIndex),
                  loading: () => const Card(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )),
                  error: (error, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error loading SANA Index: $error'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Actions
                _buildQuickActionsSection(context),
                const SizedBox(height: 16),

                // Profile Summary
                _buildProfileSummaryCard(context, profile),
              ],
            ),
          ),
        ),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(practitionerProfileProvider),
        ),
      ),
    );
  }

  Widget _buildVerificationStatusCard(BuildContext context, String status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'VERIFIED':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Verified';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Verification';
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Verification Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSanaIndexCard(BuildContext context, dynamic sanaIndex) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SANA Index',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${sanaIndex.totalScore}/100',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildScoreRow('Credentials', sanaIndex.credentialsScore, 30),
            const SizedBox(height: 8),
            _buildScoreRow('Experience', sanaIndex.experienceScore, 30),
            const SizedBox(height: 8),
            _buildScoreRow('Outcomes', sanaIndex.outcomesScore, 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, int max) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / max,
            backgroundColor: Colors.grey[200],
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 8),
        Text('$score/$max'),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              context,
              'Edit Profile',
              Icons.edit,
              () => context.push('/practitioner/profile-setup'),
            ),
            _buildActionCard(
              context,
              'Session Types',
              Icons.schedule,
              () => context.push('/practitioner/session-types'),
            ),
            _buildActionCard(
              context,
              'Availability',
              Icons.calendar_today,
              () => context.push('/practitioner/availability'),
            ),
            _buildActionCard(
              context,
              'Credentials',
              Icons.folder,
              () => context.push('/practitioner/credentials'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard(BuildContext context, dynamic profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Practice Name', profile.practiceName ?? 'Not set'),
            _buildInfoRow('Specialties', profile.specialties.join(', ')),
            _buildInfoRow('Years of Practice', '${profile.yearsOfPractice}'),
            _buildInfoRow('Professional Body', profile.professionalBody ?? 'Not set'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'Not set' : value),
          ),
        ],
      ),
    );
  }
}
