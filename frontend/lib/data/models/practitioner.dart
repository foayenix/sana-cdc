import 'package:freezed_annotation/freezed_annotation.dart';

part 'practitioner.freezed.dart';
part 'practitioner.g.dart';

@freezed
class PractitionerProfile with _$PractitionerProfile {
  const factory PractitionerProfile({
    required String id,
    required String userId,
    String? practiceName,
    String? bio,
    String? postcode,
    @Default([]) List<String> specialties,
    @Default(0) int yearsOfPractice,
    String? professionalBody,
    @Default([]) List<String> qualifications,
    String? insuranceNumber,
    String? aboutMe,
    String? approach,
    @Default([]) List<String> credentialFiles,
    @Default('PENDING') String verificationStatus,
    DateTime? verifiedAt,
    @Default(0) int sanaIndexScore,
    @Default(false) bool sanaIndexPublic,
    List<dynamic>? availabilityData,
  }) = _PractitionerProfile;

  factory PractitionerProfile.fromJson(Map<String, dynamic> json) =>
      _$PractitionerProfileFromJson(json);
}

@freezed
class PractitionerSearchResult with _$PractitionerSearchResult {
  const factory PractitionerSearchResult({
    required String id,
    required String name,
    String? profilePhoto,
    String? practiceName,
    String? bio,
    @Default([]) List<String> specialties,
    @Default(0) int yearsOfPractice,
    String? postcode,
    int? sanaIndexScore,
    @Default([]) List<SessionType> sessionTypes,
  }) = _PractitionerSearchResult;

  factory PractitionerSearchResult.fromJson(Map<String, dynamic> json) =>
      _$PractitionerSearchResultFromJson(json);
}

@freezed
class SessionType with _$SessionType {
  const factory SessionType({
    required String id,
    required String practitionerId,
    required String name,
    required String description,
    required int durationMinutes,
    required double priceGBP,
    @Default(true) bool isActive,
  }) = _SessionType;

  factory SessionType.fromJson(Map<String, dynamic> json) =>
      _$SessionTypeFromJson(json);
}

@freezed
class SanaIndexBreakdown with _$SanaIndexBreakdown {
  const factory SanaIndexBreakdown({
    required int credentialsScore,
    required int experienceScore,
    required int outcomesScore,
    required int totalScore,
  }) = _SanaIndexBreakdown;

  factory SanaIndexBreakdown.fromJson(Map<String, dynamic> json) =>
      _$SanaIndexBreakdownFromJson(json);
}

@freezed
class AvailabilitySlot with _$AvailabilitySlot {
  const factory AvailabilitySlot({
    required int dayOfWeek, // 0-6 (Sunday-Saturday)
    required String startTime, // HH:mm format
    required String endTime, // HH:mm format
  }) = _AvailabilitySlot;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) =>
      _$AvailabilitySlotFromJson(json);
}
