import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/services/practitioners_service.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedSpecialtiesProvider = StateProvider<List<String>>((ref) => []);
final postcodeProvider = StateProvider<String?>((ref) => null);

final practitionersSearchProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(practitionersServiceProvider);
  final specialties = ref.watch(selectedSpecialtiesProvider);
  final postcode = ref.watch(postcodeProvider);

  return await service.searchPractitioners(
    specialties: specialties.isNotEmpty ? specialties : null,
    postcode: postcode,
  );
});

class PractitionerSearchScreen extends ConsumerStatefulWidget {
  const PractitionerSearchScreen({super.key});

  @override
  ConsumerState<PractitionerSearchScreen> createState() => _PractitionerSearchScreenState();
}

class _PractitionerSearchScreenState extends ConsumerState<PractitionerSearchScreen> {
  final TextEditingController _postcodeController = TextEditingController();
  bool _showFilters = false;

  final List<String> _availableSpecialties = [
    'Nutritionist',
    'Personal Trainer',
    'Physiotherapist',
    'Psychologist',
    'Yoga Instructor',
    'Meditation Teacher',
    'Life Coach',
    'Acupuncturist',
    'Massage Therapist',
  ];

  @override
  void dispose() {
    _postcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(practitionersSearchProvider);
    final selectedSpecialties = ref.watch(selectedSpecialtiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Practitioners'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          if (_showFilters) _buildFiltersSection(selectedSpecialties),

          // Search Results
          Expanded(
            child: searchResultsAsync.when(
              data: (results) {
                final practitioners = results['practitioners'] as List;

                if (practitioners.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No practitioners found'),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(practitionersSearchProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: practitioners.length,
                    itemBuilder: (context, index) {
                      final practitioner = practitioners[index];
                      return _buildPractitionerCard(context, practitioner);
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => CustomErrorWidget(
                message: error.toString(),
                onRetry: () => ref.invalidate(practitionersSearchProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(List<String> selectedSpecialties) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // Postcode Filter
          TextField(
            controller: _postcodeController,
            decoration: InputDecoration(
              labelText: 'Postcode',
              hintText: 'Enter postcode',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  ref.read(postcodeProvider.notifier).state =
                      _postcodeController.text.isNotEmpty
                          ? _postcodeController.text
                          : null;
                },
              ),
            ),
            onSubmitted: (value) {
              ref.read(postcodeProvider.notifier).state =
                  value.isNotEmpty ? value : null;
            },
          ),
          const SizedBox(height: 12),

          // Specialties Filter
          Text(
            'Specialties',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableSpecialties.map((specialty) {
              final isSelected = selectedSpecialties.contains(specialty);
              return FilterChip(
                label: Text(specialty),
                selected: isSelected,
                onSelected: (selected) {
                  final newSpecialties = [...selectedSpecialties];
                  if (selected) {
                    newSpecialties.add(specialty);
                  } else {
                    newSpecialties.remove(specialty);
                  }
                  ref.read(selectedSpecialtiesProvider.notifier).state = newSpecialties;
                },
              );
            }).toList(),
          ),

          // Clear Filters Button
          if (selectedSpecialties.isNotEmpty || _postcodeController.text.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref.read(selectedSpecialtiesProvider.notifier).state = [];
                ref.read(postcodeProvider.notifier).state = null;
                _postcodeController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildPractitionerCard(BuildContext context, dynamic practitioner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to practitioner detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PractitionerDetailScreen(
                practitionerId: practitioner.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              CircleAvatar(
                radius: 32,
                backgroundImage: practitioner.profilePhoto != null
                    ? NetworkImage(practitioner.profilePhoto)
                    : null,
                child: practitioner.profilePhoto == null
                    ? Text(
                        practitioner.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practitioner.practiceName ?? practitioner.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (practitioner.specialties.isNotEmpty)
                      Text(
                        practitioner.specialties.join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    const SizedBox(height: 8),
                    if (practitioner.bio != null)
                      Text(
                        practitioner.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (practitioner.yearsOfPractice > 0)
                          Chip(
                            label: Text('${practitioner.yearsOfPractice} years'),
                            avatar: const Icon(Icons.work, size: 16),
                            visualDensity: VisualDensity.compact,
                          ),
                        const SizedBox(width: 8),
                        if (practitioner.sanaIndexScore != null)
                          Chip(
                            label: Text('SANA: ${practitioner.sanaIndexScore}'),
                            avatar: const Icon(Icons.star, size: 16),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Practitioner Detail Screen (placeholder)
class PractitionerDetailScreen extends StatelessWidget {
  final String practitionerId;

  const PractitionerDetailScreen({super.key, required this.practitionerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practitioner Profile'),
      ),
      body: const Center(
        child: Text('Practitioner Detail View - Coming Soon'),
      ),
    );
  }
}
