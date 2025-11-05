import 'package:freezed_annotation/freezed_annotation.dart';

part 'outcome.freezed.dart';
part 'outcome.g.dart';

@freezed
class Outcome with _$Outcome {
  const factory Outcome({
    required String id,
    required String appointmentId,
    required int outcomeScore, // 1-5 scale
    String? improvementNotes,
    @Default([]) List<String> goalsAchieved,
    String? nextSteps,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Outcome;

  factory Outcome.fromJson(Map<String, dynamic> json) =>
      _$OutcomeFromJson(json);
}

@freezed
class OutcomeStatistics with _$OutcomeStatistics {
  const factory OutcomeStatistics({
    required int totalOutcomes,
    required double averageScore,
    required Map<String, int> distribution,
  }) = _OutcomeStatistics;

  factory OutcomeStatistics.fromJson(Map<String, dynamic> json) =>
      _$OutcomeStatisticsFromJson(json);
}

@freezed
class CreateOutcomeRequest with _$CreateOutcomeRequest {
  const factory CreateOutcomeRequest({
    required String appointmentId,
    required int outcomeScore,
    String? improvementNotes,
    @Default([]) List<String> goalsAchieved,
    String? nextSteps,
  }) = _CreateOutcomeRequest;

  factory CreateOutcomeRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOutcomeRequestFromJson(json);
}
