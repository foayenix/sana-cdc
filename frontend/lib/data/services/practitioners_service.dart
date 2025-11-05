import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/practitioner.dart';
import 'package:sana_app/data/services/api_service.dart';

class PractitionersService {
  final Dio dio;

  PractitionersService(this.dio);

  // Get own practitioner profile
  Future<PractitionerProfile> getProfile() async {
    final response = await dio.get('/practitioners/profile');
    return PractitionerProfile.fromJson(response.data['profile']);
  }

  // Update profile
  Future<PractitionerProfile> updateProfile(Map<String, dynamic> updates) async {
    final response = await dio.put('/practitioners/profile', data: updates);
    return PractitionerProfile.fromJson(response.data['profile']);
  }

  // Upload credentials
  Future<Map<String, dynamic>> uploadCredentials(List<String> credentialFiles) async {
    final response = await dio.post(
      '/practitioners/credentials',
      data: {'credentialFiles': credentialFiles},
    );
    return response.data;
  }

  // Set availability
  Future<Map<String, dynamic>> setAvailability(List<AvailabilitySlot> availability) async {
    final response = await dio.post(
      '/practitioners/availability',
      data: {
        'availability': availability.map((slot) => slot.toJson()).toList(),
      },
    );
    return response.data;
  }

  // Get own availability
  Future<List<AvailabilitySlot>> getAvailability() async {
    final response = await dio.get('/practitioners/availability');
    final List<dynamic> data = response.data['availability'] ?? [];
    return data.map((slot) => AvailabilitySlot.fromJson(slot)).toList();
  }

  // Toggle SANA Index visibility
  Future<Map<String, dynamic>> toggleSanaIndexVisibility(bool isPublic) async {
    final response = await dio.put(
      '/practitioners/sana-index/visibility',
      data: {'isPublic': isPublic},
    );
    return response.data;
  }

  // Search practitioners (public)
  Future<Map<String, dynamic>> searchPractitioners({
    List<String>? specialties,
    String? postcode,
    int? minSanaIndex,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (specialties != null && specialties.isNotEmpty) {
      queryParams['specialties'] = specialties.join(',');
    }
    if (postcode != null) {
      queryParams['postcode'] = postcode;
    }
    if (minSanaIndex != null) {
      queryParams['minSanaIndex'] = minSanaIndex.toString();
    }

    final response = await dio.get(
      '/practitioners/search',
      queryParameters: queryParams,
    );

    final List<dynamic> practitioners = response.data['practitioners'] ?? [];
    return {
      'practitioners': practitioners
          .map((p) => PractitionerSearchResult.fromJson(p))
          .toList(),
      'pagination': response.data['pagination'],
    };
  }

  // Get public practitioner profile
  Future<PractitionerSearchResult> getPublicProfile(String practitionerId) async {
    final response = await dio.get('/practitioners/$practitionerId/public');
    return PractitionerSearchResult.fromJson(response.data);
  }

  // ADMIN: Get pending verifications
  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    final response = await dio.get('/practitioners/admin/pending-verifications');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ADMIN: Update verification status
  Future<Map<String, dynamic>> updateVerificationStatus(
    String practitionerId,
    String status, {
    String? adminNotes,
  }) async {
    final response = await dio.put(
      '/practitioners/admin/$practitionerId/verification',
      data: {
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
      },
    );
    return response.data;
  }
}

// Provider
final practitionersServiceProvider = Provider<PractitionersService>((ref) {
  final dio = ref.watch(dioProvider);
  return PractitionersService(dio);
});
