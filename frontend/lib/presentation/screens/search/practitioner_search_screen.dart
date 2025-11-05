import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/search.dart';
import '../../../data/services/search_service.dart';
import '../../../core/constants/app_constants.dart';

/// Advanced practitioner search screen with filters
class PractitionerSearchScreen extends ConsumerStatefulWidget {
  const PractitionerSearchScreen({super.key});

  @override
  ConsumerState<PractitionerSearchScreen> createState() =>
      _PractitionerSearchScreenState();
}

class _PractitionerSearchScreenState
    extends ConsumerState<PractitionerSearchScreen> {
  final _searchController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _scrollController = ScrollController();

  // Filter state
  List<String> _selectedSpecialties = [];
  List<String> _selectedModalities = [];
  String? _availableFor;
  RangeValues? _priceRange;
  double? _minRating;
  String _sortBy = 'rating';
  String _sortOrder = 'desc';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialize search on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _postcodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when scrolled to 80%
      _loadMore();
    }
  }

  void _loadMore() {
    final filters = _buildFilters();
    ref.read(searchNotifierProvider.notifier).loadMore(filters);
  }

  SearchFilters _buildFilters() {
    return SearchFilters(
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
      specialties:
          _selectedSpecialties.isNotEmpty ? _selectedSpecialties : null,
      modalities: _selectedModalities.isNotEmpty ? _selectedModalities : null,
      postcode: _postcodeController.text.isNotEmpty
          ? _postcodeController.text
          : null,
      minPrice: _priceRange?.start.toInt(),
      maxPrice: _priceRange?.end.toInt(),
      availableFor: _availableFor,
      minRating: _minRating,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      limit: 20,
      offset: 0,
    );
  }

  void _search() {
    final filters = _buildFilters();
    ref.read(searchNotifierProvider.notifier).search(filters);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _postcodeController.clear();
      _selectedSpecialties.clear();
      _selectedModalities.clear();
      _availableFor = null;
      _priceRange = null;
      _minRating = null;
      _sortBy = 'rating';
      _sortOrder = 'desc';
    });
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Practitioner'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Filters panel
          if (_showFilters) _buildFiltersPanel(searchState.filterOptions),

          // Results
          Expanded(
            child: _buildResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, specialty, or modality...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _search();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postcodeController,
                  decoration: InputDecoration(
                    hintText: 'Postcode',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(FilterOptions? options) {
    if (options == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Specialties
          _buildMultiSelectFilter(
            'Specialties',
            options.specialties,
            _selectedSpecialties,
            (selected) => setState(() => _selectedSpecialties = selected),
          ),
          const SizedBox(height: 12),

          // Modalities
          _buildMultiSelectFilter(
            'Modalities',
            options.modalities,
            _selectedModalities,
            (selected) => setState(() => _selectedModalities = selected),
          ),
          const SizedBox(height: 12),

          // Availability
          _buildDropdownFilter(
            'Availability',
            ['in-person', 'remote', 'both'],
            _availableFor,
            (value) => setState(() => _availableFor = value),
            (value) => SearchService.getAvailabilityText(value),
          ),
          const SizedBox(height: 12),

          // Price range
          _buildPriceRangeFilter(options.priceRange),
          const SizedBox(height: 12),

          // Minimum rating
          _buildRatingFilter(),
          const SizedBox(height: 12),

          // Sort options
          _buildSortOptions(),
        ],
      ),
    );
  }

  Widget _buildMultiSelectFilter(
    String label,
    List<String> options,
    List<String> selected,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newSelected = List<String>.from(this.selected);
                if (selected) {
                  newSelected.add(option);
                } else {
                  newSelected.remove(option);
                }
                onChanged(newSelected);
                _search();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    String label,
    List<String> options,
    String? value,
    Function(String?) onChanged,
    String Function(String) displayText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text('Any $label'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Any')),
            ...options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(displayText(option)),
              );
            }),
          ],
          onChanged: (newValue) {
            onChanged(newValue);
            _search();
          },
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter(PriceRange range) {
    final currentRange = _priceRange ??
        RangeValues(
          range.min.toDouble(),
          range.max.toDouble(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Price Range', style: Theme.of(context).textTheme.labelLarge),
            Text(
              '${SearchService.formatPrice(currentRange.start.toInt())} - ${SearchService.formatPrice(currentRange.end.toInt())}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        RangeSlider(
          values: currentRange,
          min: range.min.toDouble(),
          max: range.max.toDouble(),
          divisions: 20,
          onChanged: (values) => setState(() => _priceRange = values),
          onChangeEnd: (values) {
            setState(() => _priceRange = values);
            _search();
          },
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minimum Rating', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [0.0, 3.0, 4.0, 4.5].map((rating) {
            final isSelected = _minRating == rating;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rating > 0) ...[
                    const Icon(Icons.star, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toString()),
                  ] else
                    const Text('Any'),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _minRating = selected ? rating : null);
                _search();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sort By', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildSortChip('rating', 'Rating'),
            _buildSortChip('price', 'Price'),
            _buildSortChip('experience', 'Experience'),
            if (_postcodeController.text.isNotEmpty)
              _buildSortChip('distance', 'Distance'),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            if (_sortBy == value) {
              _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
            } else {
              _sortBy = value;
              _sortOrder = value == 'price' ? 'asc' : 'desc';
            }
          }
        });
        _search();
      },
    );
  }

  Widget _buildResults(SearchState state) {
    if (state.isLoading && state.response == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _search,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.response == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Search for practitioners',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Use filters to find the perfect practitioner for you',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final results = state.response!.results;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No practitioners found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${state.response!.total} practitioners found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: results.length + (state.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= results.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final practitioner = results[index];
              return _buildPractitionerCard(practitioner);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPractitionerCard(PractitionerSearchResult practitioner) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          context.push(
            '${AppConstants.routePractitionerProfile}/${practitioner.id}',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Profile photo
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: practitioner.profilePhoto != null
                        ? NetworkImage(practitioner.profilePhoto!)
                        : null,
                    child: practitioner.profilePhoto == null
                        ? Text(practitioner.name[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Name and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          practitioner.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (practitioner.practiceName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            practitioner.practiceName!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              practitioner.averageRating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              ' (${practitioner.totalReviews})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Distance and price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (practitioner.distance != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                SearchService.formatDistance(
                                  practitioner.distance!,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (practitioner.minPrice != null) ...[
                        Text(
                          'From ${SearchService.formatPrice(practitioner.minPrice!)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Bio
              if (practitioner.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  practitioner.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              // Specialties
              if (practitioner.specialties.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: practitioner.specialties.take(3).map((specialty) {
                    return Chip(
                      label: Text(specialty),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              // Verified badges
              if (practitioner.verifiedBadges.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: practitioner.verifiedBadges.map((badge) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            badge,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Session types
              if (practitioner.sessionTypes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Available Sessions',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ...practitioner.sessionTypes.take(2).map((sessionType) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${sessionType.name} (${sessionType.duration}min)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          SearchService.formatPrice(sessionType.price),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
