import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/daily_checkin.dart';
import 'package:sana_app/data/services/api_service.dart';

class CheckinService {
  final ApiService _apiService;

  CheckinService(this._apiService);

  Future<CheckinResponse> submitCheckin(CheckinRequest request) async {
    final response = await _apiService.post(
      '/checkin',
      data: request.toJson(),
    );

    return CheckinResponse.fromJson(response.data);
  }

  Future<List<DailyCheckin>> getCheckinHistory({int days = 30}) async {
    final response = await _apiService.get(
      '/checkin/history',
      queryParameters: {'days': days},
    );

    final List<dynamic> checkinsJson = response.data['data']['checkins'];
    return checkinsJson.map((json) => DailyCheckin.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getCompletionRate({int days = 30}) async {
    final response = await _apiService.get(
      '/checkin/completion-rate',
      queryParameters: {'days': days},
    );

    return response.data['data'];
  }
}

// Provider for CheckinService
final checkinServiceProvider = Provider<CheckinService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CheckinService(apiService);
});
