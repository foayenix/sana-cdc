import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_score.freezed.dart';
part 'health_score.g.dart';

@freezed
class HealthScore with _$HealthScore {
  const factory HealthScore({
    required int totalScore,
    required String status,
    required DomainScores domainScores,
  }) = _HealthScore;

  factory HealthScore.fromJson(Map<String, dynamic> json) =>
      _$HealthScoreFromJson(json);
}

@freezed
class DomainScores with _$DomainScores {
  const factory DomainScores({
    required int physical,
    required int mental,
    required int lifestyle,
    required int social,
  }) = _DomainScores;

  factory DomainScores.fromJson(Map<String, dynamic> json) =>
      _$DomainScoresFromJson(json);
}

@freezed
class HealthScoreResponse with _$HealthScoreResponse {
  const factory HealthScoreResponse({
    required bool success,
    required HealthScoreData data,
  }) = _HealthScoreResponse;

  factory HealthScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthScoreResponseFromJson(json);
}

@freezed
class HealthScoreData with _$HealthScoreData {
  const factory HealthScoreData({
    required bool completed,
    int? currentScore,
    String? currentStatus,
    Map<String, dynamic>? domainScores,
  }) = _HealthScoreData;

  factory HealthScoreData.fromJson(Map<String, dynamic> json) =>
      _$HealthScoreDataFromJson(json);
}
