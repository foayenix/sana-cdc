import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation.freezed.dart';
part 'recommendation.g.dart';

@freezed
class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String id,
    required String slug,
    required String title,
    required String category,
    required String content,
    required List<Citation> citations,
    DateTime? createdAt,
  }) = _Recommendation;

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);
}

@freezed
class Citation with _$Citation {
  const factory Citation({
    required String title,
    required String url,
  }) = _Citation;

  factory Citation.fromJson(Map<String, dynamic> json) =>
      _$CitationFromJson(json);
}

@freezed
class RecommendationListResponse with _$RecommendationListResponse {
  const factory RecommendationListResponse({
    required bool success,
    required List<Recommendation> data,
  }) = _RecommendationListResponse;

  factory RecommendationListResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationListResponseFromJson(json);
}

@freezed
class RecommendationDetailResponse with _$RecommendationDetailResponse {
  const factory RecommendationDetailResponse({
    required bool success,
    required Recommendation data,
  }) = _RecommendationDetailResponse;

  factory RecommendationDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationDetailResponseFromJson(json);
}
