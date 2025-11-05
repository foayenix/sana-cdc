import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/health_score.dart';
import 'package:sana_app/data/models/questionnaire_response.dart';
import 'package:sana_app/data/services/api_service.dart';

class QuestionnaireService {
  final ApiService _apiService;

  QuestionnaireService(this._apiService);

  Future<Map<String, dynamic>> submitQuestionnaire(
    QuestionnaireResponse response,
  ) async {
    final result = await _apiService.post(
      '/questionnaire',
      data: response.toJson(),
    );

    return result.data;
  }

  Future<HealthScoreData> getHealthScore() async {
    final response = await _apiService.get('/questionnaire/score');
    return HealthScoreData.fromJson(response.data['data']);
  }

  Future<List<String>> getTopLevers() async {
    final response = await _apiService.get('/questionnaire/levers');
    return List<String>.from(response.data['data']['levers']);
  }
}

// Provider for QuestionnaireService
final questionnaireServiceProvider = Provider<QuestionnaireService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return QuestionnaireService(apiService);
});
