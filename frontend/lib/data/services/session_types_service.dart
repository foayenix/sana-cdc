import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/practitioner.dart';
import 'package:sana_app/data/services/api_service.dart';

class SessionTypesService {
  final Dio dio;

  SessionTypesService(this.dio);

  // Create session type
  Future<SessionType> createSessionType({
    required String name,
    required String description,
    required int durationMinutes,
    required double priceGBP,
    bool isActive = true,
  }) async {
    final response = await dio.post(
      '/session-types',
      data: {
        'name': name,
        'description': description,
        'durationMinutes': durationMinutes,
        'priceGBP': priceGBP,
        'isActive': isActive,
      },
    );
    return SessionType.fromJson(response.data['sessionType']);
  }

  // Get my session types
  Future<List<SessionType>> getMySessionTypes({bool includeInactive = false}) async {
    final response = await dio.get(
      '/session-types/my-sessions',
      queryParameters: {'includeInactive': includeInactive.toString()},
    );
    final List<dynamic> data = response.data ?? [];
    return data.map((session) => SessionType.fromJson(session)).toList();
  }

  // Get session types for a practitioner (public)
  Future<List<SessionType>> getPractitionerSessionTypes(String practitionerId) async {
    final response = await dio.get('/session-types/practitioner/$practitionerId');
    final List<dynamic> data = response.data ?? [];
    return data.map((session) => SessionType.fromJson(session)).toList();
  }

  // Get single session type by ID
  Future<SessionType> getSessionTypeById(String sessionTypeId) async {
    final response = await dio.get('/session-types/$sessionTypeId');
    return SessionType.fromJson(response.data);
  }

  // Update session type
  Future<SessionType> updateSessionType(
    String sessionTypeId,
    Map<String, dynamic> updates,
  ) async {
    final response = await dio.put(
      '/session-types/$sessionTypeId',
      data: updates,
    );
    return SessionType.fromJson(response.data['sessionType']);
  }

  // Delete session type
  Future<Map<String, dynamic>> deleteSessionType(String sessionTypeId) async {
    final response = await dio.delete('/session-types/$sessionTypeId');
    return response.data;
  }
}

// Provider
final sessionTypesServiceProvider = Provider<SessionTypesService>((ref) {
  final dio = ref.watch(dioProvider);
  return SessionTypesService(dio);
});
