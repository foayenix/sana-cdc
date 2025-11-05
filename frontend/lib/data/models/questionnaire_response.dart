import 'package:freezed_annotation/freezed_annotation.dart';

part 'questionnaire_response.freezed.dart';
part 'questionnaire_response.g.dart';

@freezed
class QuestionnaireResponse with _$QuestionnaireResponse {
  const factory QuestionnaireResponse({
    // Physical Domain
    required double sleepHours,
    required int sleepQuality,
    required int painLevel,
    required int energyLevel,
    // Mental Domain
    required int moodScore,
    required int anxietyLevel,
    required int stressLevel,
    // Lifestyle Domain
    required int exerciseMinutesPerWeek,
    required int dietQuality,
    required int alcoholDrinksPerWeek,
    // Social Domain
    required int socialConnection,
    required int lifeSatisfaction,
    required int workLifeBalance,
    // Additional Context
    required List<String> mainHealthConcerns,
    required List<String> practitionerTypesLooking,
  }) = _QuestionnaireResponse;

  factory QuestionnaireResponse.fromJson(Map<String, dynamic> json) =>
      _$QuestionnaireResponseFromJson(json);
}
