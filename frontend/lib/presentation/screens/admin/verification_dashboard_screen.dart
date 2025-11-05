import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/services/practitioners_service.dart';

final pendingVerificationsProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(practitionersServiceProvider);
  return await service.getPendingVerifications();
});

class VerificationDashboardScreen extends ConsumerWidget {
  const VerificationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(pendingVerificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingVerificationsProvider),
          ),
        ],
      ),
      body: verificationsAsync.when(
        data: (verifications) {
          if (verifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingVerificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: verifications.length,
              itemBuilder: (context, index) {
                final practitioner = verifications[index];
                return _buildPractitionerCard(context, ref, practitioner);
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(pendingVerificationsProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No Pending Verifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'All practitioners have been verified',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPractitionerCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> practitioner,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(practitioner['name'][0].toUpperCase()),
        ),
        title: Text(
          practitioner['practiceName'] ?? practitioner['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(practitioner['email']),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.work, size: 14),
                const SizedBox(width: 4),
                Text('${practitioner['yearsOfPractice']} years'),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Specialties
                if (practitioner['specialties'] != null &&
                    (practitioner['specialties'] as List).isNotEmpty) ...[
                  Text(
                    'Specialties:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (practitioner['specialties'] as List)
                        .map<Widget>((specialty) => Chip(
                              label: Text(specialty),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Professional Body
                if (practitioner['professionalBody'] != null) ...[
                  _buildInfoRow(
                    context,
                    'Professional Body',
                    practitioner['professionalBody'],
                  ),
                ],

                // Qualifications
                if (practitioner['qualifications'] != null &&
                    (practitioner['qualifications'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Qualifications:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...(practitioner['qualifications'] as List)
                      .map<Widget>((qual) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.school, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(qual)),
                              ],
                            ),
                          )),
                  const SizedBox(height: 16),
                ],

                // Credential Files
                if (practitioner['credentialFiles'] != null &&
                    (practitioner['credentialFiles'] as List).isNotEmpty) ...[
                  Text(
                    'Credential Files:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...(practitioner['credentialFiles'] as List)
                      .map<Widget>((file) => Card(
                            color: Colors.blue[50],
                            child: ListTile(
                              leading: const Icon(Icons.file_present, color: Colors.blue),
                              title: Text(file.toString().split('/').last),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('File viewing coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )),
                  const SizedBox(height: 16),
                ],

                // Submitted Date
                Text(
                  'Submitted: ${_formatDate(practitioner['submittedAt'])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyPractitioner(
                          context,
                          ref,
                          practitioner['userId'],
                          true,
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _verifyPractitioner(
                          context,
                          ref,
                          practitioner['userId'],
                          false,
                        ),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _verifyPractitioner(
    BuildContext context,
    WidgetRef ref,
    String practitionerId,
    bool approve,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Practitioner' : 'Reject Practitioner'),
        content: Text(
          approve
              ? 'Are you sure you want to approve this practitioner? They will be able to offer services to clients.'
              : 'Are you sure you want to reject this practitioner? They will need to re-submit their credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(practitionersServiceProvider);
        await service.updateVerificationStatus(
          practitionerId,
          approve ? 'VERIFIED' : 'REJECTED',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                approve
                    ? 'Practitioner approved successfully'
                    : 'Practitioner rejected',
              ),
              backgroundColor: approve ? Colors.green : Colors.orange,
            ),
          );
          ref.invalidate(pendingVerificationsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
