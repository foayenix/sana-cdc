import 'package:freezed_annotation/freezed_annotation.dart';

part 'search.freezed.dart';
part 'search.g.dart';

/// Search filters for practitioner search
@freezed
class SearchFilters with _$SearchFilters {
  const factory SearchFilters({
    String? query,
    List<String>? specialties,
    List<String>? modalities,
    String? postcode,
    @Default(50) int maxDistance,
    int? minPrice,
    int? maxPrice,
    String? availableFor,
    double? minRating,
    @Default('rating') String sortBy,
    @Default('desc') String sortOrder,
    @Default(20) int limit,
    @Default(0) int offset,
  }) = _SearchFilters;

  factory SearchFilters.fromJson(Map<String, dynamic> json) =>
      _$SearchFiltersFromJson(json);
}

/// Practitioner search result
@freezed
class PractitionerSearchResult with _$PractitionerSearchResult {
  const factory PractitionerSearchResult({
    required String id,
    required String userId,
    required String name,
    String? practiceName,
    String? bio,
    String? profilePhoto,
    String? postcode,
    required List<String> specialties,
    required List<String> modalities,
    required List<String> languagesSpoken,
    int? yearsOfPractice,
    required List<String> verifiedBadges,
    required int sanaIndexScore,
    required double averageRating,
    required int totalReviews,
    int? minPrice,
    int? maxPrice,
    required List<SessionTypeSummary> sessionTypes,
    double? distance,
  }) = _PractitionerSearchResult;

  factory PractitionerSearchResult.fromJson(Map<String, dynamic> json) =>
      _$PractitionerSearchResultFromJson(json);
}

/// Session type summary (used in search results)
@freezed
class SessionTypeSummary with _$SessionTypeSummary {
  const factory SessionTypeSummary({
    required String id,
    required String name,
    required int duration,
    required int price,
    required String availableFor,
  }) = _SessionTypeSummary;

  factory SessionTypeSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionTypeSummaryFromJson(json);
}

/// Search response
@freezed
class SearchResponse with _$SearchResponse {
  const factory SearchResponse({
    required List<PractitionerSearchResult> results,
    required int total,
    required SearchFilters filters,
  }) = _SearchResponse;

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseFromJson(json);
}

/// Filter options (for dropdowns)
@freezed
class FilterOptions with _$FilterOptions {
  const factory FilterOptions({
    required List<String> specialties,
    required List<String> modalities,
    required PriceRange priceRange,
  }) = _FilterOptions;

  factory FilterOptions.fromJson(Map<String, dynamic> json) =>
      _$FilterOptionsFromJson(json);
}

/// Price range
@freezed
class PriceRange with _$PriceRange {
  const factory PriceRange({
    required int min,
    required int max,
  }) = _PriceRange;

  factory PriceRange.fromJson(Map<String, dynamic> json) =>
      _$PriceRangeFromJson(json);
}

/// Popular search terms response
@freezed
class PopularTermsResponse with _$PopularTermsResponse {
  const factory PopularTermsResponse({
    required List<String> terms,
  }) = _PopularTermsResponse;

  factory PopularTermsResponse.fromJson(Map<String, dynamic> json) =>
      _$PopularTermsResponseFromJson(json);
}

/// Sort option
enum SortBy {
  rating,
  distance,
  price,
  experience,
}

/// Sort order
enum SortOrder {
  asc,
  desc,
}

/// Availability type
enum AvailabilityType {
  inPerson('in-person'),
  remote('remote'),
  both('both');

  final String value;
  const AvailabilityType(this.value);
}
