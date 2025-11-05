import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search.dart';
import 'api_service.dart';

/// Provider for SearchService
final searchServiceProvider = Provider<SearchService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SearchService(apiService);
});

/// Service for practitioner search and filtering
class SearchService {
  final ApiService _apiService;

  SearchService(this._apiService);

  /// Search for practitioners with filters
  Future<SearchResponse> searchPractitioners(SearchFilters filters) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {};

      if (filters.query != null && filters.query!.isNotEmpty) {
        queryParams['query'] = filters.query;
      }
      if (filters.specialties != null && filters.specialties!.isNotEmpty) {
        queryParams['specialties'] = filters.specialties!.join(',');
      }
      if (filters.modalities != null && filters.modalities!.isNotEmpty) {
        queryParams['modalities'] = filters.modalities!.join(',');
      }
      if (filters.postcode != null && filters.postcode!.isNotEmpty) {
        queryParams['postcode'] = filters.postcode;
      }
      queryParams['maxDistance'] = filters.maxDistance;

      if (filters.minPrice != null) {
        queryParams['minPrice'] = filters.minPrice;
      }
      if (filters.maxPrice != null) {
        queryParams['maxPrice'] = filters.maxPrice;
      }
      if (filters.availableFor != null && filters.availableFor!.isNotEmpty) {
        queryParams['availableFor'] = filters.availableFor;
      }
      if (filters.minRating != null) {
        queryParams['minRating'] = filters.minRating;
      }

      queryParams['sortBy'] = filters.sortBy;
      queryParams['sortOrder'] = filters.sortOrder;
      queryParams['limit'] = filters.limit;
      queryParams['offset'] = filters.offset;

      final response = await _apiService.dio.get(
        '/search/practitioners',
        queryParameters: queryParams,
      );

      return SearchResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to search practitioners',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Get filter options for the search UI
  Future<FilterOptions> getFilterOptions() async {
    try {
      final response = await _apiService.dio.get('/search/filter-options');
      return FilterOptions.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load filter options',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Get popular search terms for autocomplete
  Future<List<String>> getPopularSearchTerms() async {
    try {
      final response = await _apiService.dio.get('/search/popular-terms');
      final data = PopularTermsResponse.fromJson(response.data);
      return data.terms;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load popular terms',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Format price in pence to pounds string
  static String formatPrice(int pence) {
    return '£${(pence / 100).toStringAsFixed(2)}';
  }

  /// Format distance
  static String formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  /// Get display text for availability type
  static String getAvailabilityText(String availableFor) {
    switch (availableFor) {
      case 'in-person':
        return 'In-person';
      case 'remote':
        return 'Remote';
      case 'both':
        return 'Both';
      default:
        return availableFor;
    }
  }
}

/// State notifier for search state
class SearchState {
  final SearchResponse? response;
  final FilterOptions? filterOptions;
  final List<String>? popularTerms;
  final bool isLoading;
  final String? error;

  SearchState({
    this.response,
    this.filterOptions,
    this.popularTerms,
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    SearchResponse? response,
    FilterOptions? filterOptions,
    List<String>? popularTerms,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      response: response ?? this.response,
      filterOptions: filterOptions ?? this.filterOptions,
      popularTerms: popularTerms ?? this.popularTerms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// State notifier for managing search
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;

  SearchNotifier(this._searchService) : super(SearchState());

  /// Initialize search (load filter options and popular terms)
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final filterOptions = await _searchService.getFilterOptions();
      final popularTerms = await _searchService.getPopularSearchTerms();

      state = state.copyWith(
        filterOptions: filterOptions,
        popularTerms: popularTerms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Search with filters
  Future<void> search(SearchFilters filters) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _searchService.searchPractitioners(filters);

      state = state.copyWith(response: response, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more results (pagination)
  Future<void> loadMore(SearchFilters filters) async {
    if (state.response == null || state.isLoading) return;

    final currentResults = state.response!.results;
    if (currentResults.length >= state.response!.total) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final newFilters = filters.copyWith(
        offset: currentResults.length,
      );

      final response = await _searchService.searchPractitioners(newFilters);

      final updatedResponse = state.response!.copyWith(
        results: [...currentResults, ...response.results],
      );

      state = state.copyWith(response: updatedResponse, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear search results
  void clearResults() {
    state = state.copyWith(response: null, error: null);
  }
}

/// Provider for search state notifier
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchNotifier(searchService);
});
