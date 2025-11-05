import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/models/admin.dart';

class PractitionerVerificationScreen extends ConsumerStatefulWidget {
  const PractitionerVerificationScreen({super.key});

  @override
  ConsumerState<PractitionerVerificationScreen> createState() =>
      _PractitionerVerificationScreenState();
}

class _PractitionerVerificationScreenState
    extends ConsumerState<PractitionerVerificationScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(verificationsProvider.notifier).loadVerifications();
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

    final verificationsState = ref.read(verificationsProvider);
    if (verificationsState.practitioners.length >=
        verificationsState.total) {
      return;
    }

    setState(() => _isLoadingMore = true);
    await ref.read(verificationsProvider.notifier).loadVerifications(
          offset: verificationsState.practitioners.length,
        );
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final verificationsState = ref.watch(verificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practitioner Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(verificationsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: verificationsState.isLoading &&
              verificationsState.practitioners.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : verificationsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${verificationsState.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(verificationsProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : verificationsState.practitioners.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('No pending verifications'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.read(verificationsProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: verificationsState.practitioners.length +
                            (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index ==
                              verificationsState.practitioners.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final practitioner =
                              verificationsState.practitioners[index];
                          return _buildPractitionerCard(practitioner);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPractitionerCard(PendingPractitioner practitioner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    practitioner.user.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        practitioner.user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        practitioner.user.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    practitioner.verificationStatus,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: _getStatusColor(practitioner.verificationStatus)
                      .withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const Divider(height: 24),
            if (practitioner.bio != null) ...[
              const Text(
                'Bio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(practitioner.bio!),
              const SizedBox(height: 12),
            ],
            if (practitioner.specialties != null &&
                practitioner.specialties!.isNotEmpty) ...[
              const Text(
                'Specialties',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: practitioner.specialties!
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (practitioner.modalities != null &&
                practitioner.modalities!.isNotEmpty) ...[
              const Text(
                'Modalities',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: practitioner.modalities!
                    .map((m) => Chip(label: Text(m)))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (practitioner.certifications != null &&
                practitioner.certifications!.isNotEmpty) ...[
              const Text(
                'Certifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...practitioner.certifications!.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(child: Text(c)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (practitioner.yearsOfExperience != null) ...[
              Row(
                children: [
                  const Icon(Icons.work, size: 16),
                  const SizedBox(width: 4),
                  Text('${practitioner.yearsOfExperience} years of experience'),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (practitioner.credentialUrls != null &&
                practitioner.credentialUrls!.isNotEmpty) ...[
              const Text(
                'Credentials',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...practitioner.credentialUrls!.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text('View Credential ${index + 1}'),
                    onPressed: () => _openUrl(url),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            Text(
              'Submitted: ${practitioner.createdAt.toString().substring(0, 10)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _updateStatus(
                      practitioner.id,
                      'APPROVED',
                      practitioner.user.name,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () => _updateStatus(
                      practitioner.id,
                      'REJECTED',
                      practitioner.user.name,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'UNDER_REVIEW':
        return Colors.blue;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $url')),
        );
      }
    }
  }

  Future<void> _updateStatus(
    String practitionerId,
    String status,
    String practitionerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status == 'APPROVED' ? 'Approve' : 'Reject'} Verification'),
        content: Text(
          'Are you sure you want to ${status == 'APPROVED' ? 'approve' : 'reject'} $practitionerName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(status == 'APPROVED' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Get actual admin ID from auth state
        const adminId = 'admin-id-placeholder';
        await ref.read(verificationsProvider.notifier).updateStatus(
              practitionerId: practitionerId,
              status: status,
              adminId: adminId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Verification ${status.toLowerCase()} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
