import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/services/practitioners_service.dart';
import 'package:sana_app/data/services/session_types_service.dart';

final practitionerDetailProvider =
    FutureProvider.autoDispose.family((ref, String practitionerId) async {
  final service = ref.watch(practitionersServiceProvider);
  return await service.getPublicProfile(practitionerId);
});

final practitionerSessionsProvider =
    FutureProvider.autoDispose.family((ref, String practitionerId) async {
  final service = ref.watch(sessionTypesServiceProvider);
  return await service.getPractitionerSessionTypes(practitionerId);
});

class PractitionerDetailScreen extends ConsumerWidget {
  final String practitionerId;

  const PractitionerDetailScreen({super.key, required this.practitionerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practitionerAsync = ref.watch(practitionerDetailProvider(practitionerId));
    final sessionsAsync = ref.watch(practitionerSessionsProvider(practitionerId));

    return Scaffold(
      body: practitionerAsync.when(
        data: (practitioner) => CustomScrollView(
          slivers: [
            _buildAppBar(context, practitioner),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(context, practitioner),
                  _buildAboutSection(context, practitioner),
                  _buildApproachSection(context, practitioner),
                  _buildQualificationsSection(context, practitioner),
                  sessionsAsync.when(
                    data: (sessions) => _buildSessionsSection(context, sessions),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(practitionerDetailProvider(practitionerId)),
        ),
      ),
      bottomNavigationBar: practitionerAsync.maybeWhen(
        data: (practitioner) => _buildBottomBar(context, practitioner),
        orElse: () => null,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic practitioner) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: practitioner.profilePhoto != null
                        ? NetworkImage(practitioner.profilePhoto)
                        : null,
                    child: practitioner.profilePhoto == null
                        ? Text(
                            practitioner.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          practitioner.practiceName ?? practitioner.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (practitioner.postcode != null)
                          Text(
                            practitioner.postcode,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
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

  Widget _buildHeaderSection(BuildContext context, dynamic practitioner) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (practitioner.bio != null) ...[
            Text(
              practitioner.bio,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (practitioner.yearsOfPractice > 0)
                Chip(
                  avatar: const Icon(Icons.work, size: 18),
                  label: Text('${practitioner.yearsOfPractice} years experience'),
                ),
              if (practitioner.sanaIndexScore != null)
                Chip(
                  avatar: const Icon(Icons.star, size: 18),
                  label: Text('SANA Index: ${practitioner.sanaIndexScore}'),
                  backgroundColor: Colors.amber[100],
                ),
              ...practitioner.specialties.map<Widget>((specialty) => Chip(
                    label: Text(specialty),
                    backgroundColor: Colors.blue[50],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, dynamic practitioner) {
    if (practitioner.aboutMe == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            practitioner.aboutMe,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildApproachSection(BuildContext context, dynamic practitioner) {
    if (practitioner.approach == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approach',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            practitioner.approach,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationsSection(BuildContext context, dynamic practitioner) {
    if ((practitioner.qualifications?.isEmpty ?? true) &&
        practitioner.professionalBody == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Background',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (practitioner.professionalBody != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.blue),
                title: const Text('Professional Body'),
                subtitle: Text(practitioner.professionalBody),
              ),
            ),
          ],
          if (practitioner.qualifications?.isNotEmpty ?? false)
            ...practitioner.qualifications.map<Widget>((qual) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Colors.green),
                    title: Text(qual),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSessionsSection(BuildContext context, List<dynamic> sessions) {
    if (sessions.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sessions Offered',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...sessions.map((session) => Card(
                child: ListTile(
                  title: Text(session.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(session.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${session.durationMinutes} minutes'),
                          const SizedBox(width: 16),
                          Icon(Icons.payments, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('£${session.priceGBP.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, dynamic practitioner) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: CustomButton(
        text: 'Book Appointment',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking feature coming in Phase 3!'),
            ),
          );
        },
      ),
    );
  }
}
