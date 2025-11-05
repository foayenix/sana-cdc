import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/health_score.dart';
import 'package:sana_app/data/services/questionnaire_service.dart';

final healthScoreProvider =
    FutureProvider.autoDispose<HealthScoreData>((ref) async {
  final service = ref.watch(questionnaireServiceProvider);
  return await service.getHealthScore();
});

final topLeversProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final service = ref.watch(questionnaireServiceProvider);
  return await service.getTopLevers();
});
