import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/practitioner.dart';
import 'package:sana_app/data/services/api_service.dart';

class SanaIndexService {
  final Dio dio;

  SanaIndexService(this.dio);

  // Get own SANA Index breakdown
  Future<SanaIndexBreakdown> getMyIndex() async {
    final response = await dio.get('/sana-index/my-index');
    return SanaIndexBreakdown.fromJson(response.data);
  }

  // Recalculate own SANA Index
  Future<Map<String, dynamic>> recalculateMyIndex() async {
    final response = await dio.post('/sana-index/recalculate');
    return response.data;
  }

  // Get SANA Index for a practitioner (public)
  Future<int> getPractitionerIndex(String practitionerId) async {
    final response = await dio.get('/sana-index/practitioner/$practitionerId');
    return response.data['totalScore'];
  }
}

// Provider
final sanaIndexServiceProvider = Provider<SanaIndexService>((ref) {
  final dio = ref.watch(dioProvider);
  return SanaIndexService(dio);
});
