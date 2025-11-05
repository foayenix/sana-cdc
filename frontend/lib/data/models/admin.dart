import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin.freezed.dart';
part 'admin.g.dart';

// Platform Statistics
@freezed
class PlatformStats with _$PlatformStats {
  const factory PlatformStats({
    required int totalUsers,
    required int totalClients,
    required int totalPractitioners,
    required int totalAppointments,
    required double totalRevenue,
    required int pendingVerifications,
    required int activeConversations,
    required int totalReviews,
  }) = _PlatformStats;

  factory PlatformStats.fromJson(Map<String, dynamic> json) =>
      _$PlatformStatsFromJson(json);
}

// User Management
@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    required String id,
    required String email,
    required String name,
    required String role,
    required bool isActive,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    DateTime? updatedAt,
    AdminClientProfile? clientProfile,
    AdminPractitionerProfile? practitionerProfile,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}

@freezed
class AdminClientProfile with _$AdminClientProfile {
  const factory AdminClientProfile({
    required String id,
    String? dateOfBirth,
    String? phone,
    String? address,
    String? postcode,
    String? city,
    String? state,
    String? country,
    List<String>? primaryConcerns,
    List<String>? preferredModalities,
  }) = _AdminClientProfile;

  factory AdminClientProfile.fromJson(Map<String, dynamic> json) =>
      _$AdminClientProfileFromJson(json);
}

@freezed
class AdminPractitionerProfile with _$AdminPractitionerProfile {
  const factory AdminPractitionerProfile({
    required String id,
    String? bio,
    List<String>? specialties,
    List<String>? modalities,
    List<String>? certifications,
    int? yearsOfExperience,
    String? phone,
    String? officeAddress,
    String? postcode,
    String? city,
    String? state,
    String? country,
    required String verificationStatus,
    List<String>? credentialUrls,
    double? rating,
    int? reviewCount,
  }) = _AdminPractitionerProfile;

  factory AdminPractitionerProfile.fromJson(Map<String, dynamic> json) =>
      _$AdminPractitionerProfileFromJson(json);
}

@freezed
class GetUsersResponse with _$GetUsersResponse {
  const factory GetUsersResponse({
    required List<AdminUser> users,
    required int total,
  }) = _GetUsersResponse;

  factory GetUsersResponse.fromJson(Map<String, dynamic> json) =>
      _$GetUsersResponseFromJson(json);
}

// Practitioner Verification
@freezed
class PendingPractitioner with _$PendingPractitioner {
  const factory PendingPractitioner({
    required String id,
    String? bio,
    List<String>? specialties,
    List<String>? modalities,
    List<String>? certifications,
    int? yearsOfExperience,
    required String verificationStatus,
    List<String>? credentialUrls,
    required DateTime createdAt,
    required PractitionerUser user,
  }) = _PendingPractitioner;

  factory PendingPractitioner.fromJson(Map<String, dynamic> json) =>
      _$PendingPractitionerFromJson(json);
}

@freezed
class PractitionerUser with _$PractitionerUser {
  const factory PractitionerUser({
    required String id,
    required String name,
    required String email,
    required DateTime createdAt,
  }) = _PractitionerUser;

  factory PractitionerUser.fromJson(Map<String, dynamic> json) =>
      _$PractitionerUserFromJson(json);
}

@freezed
class GetPendingVerificationsResponse with _$GetPendingVerificationsResponse {
  const factory GetPendingVerificationsResponse({
    required List<PendingPractitioner> practitioners,
    required int total,
  }) = _GetPendingVerificationsResponse;

  factory GetPendingVerificationsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetPendingVerificationsResponseFromJson(json);
}

// Review Management
@freezed
class AdminReview with _$AdminReview {
  const factory AdminReview({
    required String id,
    required int rating,
    String? comment,
    required bool isPublished,
    required DateTime createdAt,
    DateTime? updatedAt,
    required AdminReviewPractitioner practitioner,
    required AdminReviewClient client,
  }) = _AdminReview;

  factory AdminReview.fromJson(Map<String, dynamic> json) =>
      _$AdminReviewFromJson(json);
}

@freezed
class AdminReviewPractitioner with _$AdminReviewPractitioner {
  const factory AdminReviewPractitioner({
    required String id,
    required AdminReviewUser user,
  }) = _AdminReviewPractitioner;

  factory AdminReviewPractitioner.fromJson(Map<String, dynamic> json) =>
      _$AdminReviewPractitionerFromJson(json);
}

@freezed
class AdminReviewClient with _$AdminReviewClient {
  const factory AdminReviewClient({
    required String id,
    required AdminReviewUser user,
  }) = _AdminReviewClient;

  factory AdminReviewClient.fromJson(Map<String, dynamic> json) =>
      _$AdminReviewClientFromJson(json);
}

@freezed
class AdminReviewUser with _$AdminReviewUser {
  const factory AdminReviewUser({
    required String name,
  }) = _AdminReviewUser;

  factory AdminReviewUser.fromJson(Map<String, dynamic> json) =>
      _$AdminReviewUserFromJson(json);
}

@freezed
class GetReviewsResponse with _$GetReviewsResponse {
  const factory GetReviewsResponse({
    required List<AdminReview> reviews,
    required int total,
  }) = _GetReviewsResponse;

  factory GetReviewsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetReviewsResponseFromJson(json);
}

// Appointment Management
@freezed
class AdminAppointment with _$AdminAppointment {
  const factory AdminAppointment({
    required String id,
    required DateTime scheduledAt,
    required String status,
    String? notes,
    String? videoLink,
    required DateTime createdAt,
    DateTime? updatedAt,
    required AdminAppointmentUser client,
    required AdminAppointmentUser practitioner,
    required AdminAppointmentSessionType sessionType,
  }) = _AdminAppointment;

  factory AdminAppointment.fromJson(Map<String, dynamic> json) =>
      _$AdminAppointmentFromJson(json);
}

@freezed
class AdminAppointmentUser with _$AdminAppointmentUser {
  const factory AdminAppointmentUser({
    required String id,
    required String name,
    required String email,
  }) = _AdminAppointmentUser;

  factory AdminAppointmentUser.fromJson(Map<String, dynamic> json) =>
      _$AdminAppointmentUserFromJson(json);
}

@freezed
class AdminAppointmentSessionType with _$AdminAppointmentSessionType {
  const factory AdminAppointmentSessionType({
    required String name,
    required int duration,
    required double price,
  }) = _AdminAppointmentSessionType;

  factory AdminAppointmentSessionType.fromJson(Map<String, dynamic> json) =>
      _$AdminAppointmentSessionTypeFromJson(json);
}

@freezed
class GetAppointmentsResponse with _$GetAppointmentsResponse {
  const factory GetAppointmentsResponse({
    required List<AdminAppointment> appointments,
    required int total,
  }) = _GetAppointmentsResponse;

  factory GetAppointmentsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetAppointmentsResponseFromJson(json);
}

// User Activity Stats
@freezed
class UserActivityStats with _$UserActivityStats {
  const factory UserActivityStats({
    required int appointmentCount,
    required int messageCount,
    required int reviewsGiven,
    required int reviewsReceived,
    DateTime? lastLoginAt,
    required DateTime createdAt,
  }) = _UserActivityStats;

  factory UserActivityStats.fromJson(Map<String, dynamic> json) =>
      _$UserActivityStatsFromJson(json);
}
