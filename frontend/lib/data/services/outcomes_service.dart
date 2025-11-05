import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/outcome.dart';
import 'package:sana_app/data/services/api_service.dart';

class OutcomesService {
  final Dio dio;

  OutcomesService(this.dio);

  // Create client outcome (practitioner only, after completed appointment)
  Future<Outcome> createOutcome({
    required String appointmentId,
    required int outcomeScore,
    String? improvementNotes,
    List<String>? goalsAchieved,
    String? nextSteps,
  }) async {
    final response = await dio.post(
      '/outcomes',
      data: {
        'appointmentId': appointmentId,
        'outcomeScore': outcomeScore,
        if (improvementNotes != null) 'improvementNotes': improvementNotes,
        if (goalsAchieved != null) 'goalsAchieved': goalsAchieved,
        if (nextSteps != null) 'nextSteps': nextSteps,
      },
    );
    return Outcome.fromJson(response.data);
  }

  // Get all outcomes for authenticated user
  Future<List<Outcome>> getOutcomes() async {
    final response = await dio.get('/outcomes');
    final List<dynamic> data = response.data ?? [];
    return data.map((outcome) => Outcome.fromJson(outcome)).toList();
  }

  // Get outcome statistics for practitioner
  Future<OutcomeStatistics> getOutcomeStatistics() async {
    final response = await dio.get('/outcomes/stats');
    return OutcomeStatistics.fromJson(response.data);
  }

  // Get single outcome by ID
  Future<Outcome> getOutcomeById(String outcomeId) async {
    final response = await dio.get('/outcomes/$outcomeId');
    return Outcome.fromJson(response.data);
  }

  // Update outcome (practitioner only)
  Future<Outcome> updateOutcome({
    required String outcomeId,
    int? outcomeScore,
    String? improvementNotes,
    List<String>? goalsAchieved,
    String? nextSteps,
  }) async {
    final updateData = <String, dynamic>{};
    if (outcomeScore != null) updateData['outcomeScore'] = outcomeScore;
    if (improvementNotes != null) updateData['improvementNotes'] = improvementNotes;
    if (goalsAchieved != null) updateData['goalsAchieved'] = goalsAchieved;
    if (nextSteps != null) updateData['nextSteps'] = nextSteps;

    final response = await dio.put(
      '/outcomes/$outcomeId',
      data: updateData,
    );
    return Outcome.fromJson(response.data);
  }

  // Delete outcome (practitioner only)
  Future<Map<String, dynamic>> deleteOutcome(String outcomeId) async {
    final response = await dio.delete('/outcomes/$outcomeId');
    return response.data;
  }
}

// Provider
final outcomesServiceProvider = Provider<OutcomesService>((ref) {
  final dio = ref.watch(dioProvider);
  return OutcomesService(dio);
});
