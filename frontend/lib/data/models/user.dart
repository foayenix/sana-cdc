import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole {
  @JsonValue('CLIENT')
  client,
  @JsonValue('PRACTITIONER')
  practitioner,
  @JsonValue('ADMIN')
  admin,
}

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    required UserRole role,
    String? profilePhoto,
    DateTime? createdAt,
    ClientProfile? clientProfile,
    PractitionerProfile? practitionerProfile,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class ClientProfile with _$ClientProfile {
  const factory ClientProfile({
    required String id,
    required bool questionnaireCompleted,
    required int currentScore,
    String? currentStatus,
    Map<String, dynamic>? domainScores,
  }) = _ClientProfile;

  factory ClientProfile.fromJson(Map<String, dynamic> json) =>
      _$ClientProfileFromJson(json);
}

@freezed
class PractitionerProfile with _$PractitionerProfile {
  const factory PractitionerProfile({
    required String id,
    String? practiceName,
    String? bio,
    String? postcode,
    String? phone,
    String? website,
    List<String>? specialties,
    List<String>? modalities,
    String? verificationStatus,
    List<String>? verifiedBadges,
    int? sanaIndexScore,
  }) = _PractitionerProfile;

  factory PractitionerProfile.fromJson(Map<String, dynamic> json) =>
      _$PractitionerProfileFromJson(json);
}
