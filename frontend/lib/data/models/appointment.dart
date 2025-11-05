import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sana_app/data/models/practitioner.dart';

part 'appointment.freezed.dart';
part 'appointment.g.dart';

enum AppointmentStatus {
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('NO_SHOW')
  noShow,
}

@freezed
class Appointment with _$Appointment {
  const factory Appointment({
    required String id,
    required String clientId,
    required String practitionerId,
    required String sessionTypeId,
    required DateTime appointmentDate,
    required AppointmentStatus status,
    String? notes,
    String? cancellationReason,
    DateTime? cancelledAt,
    required DateTime createdAt,
    DateTime? updatedAt,
    // Related data
    SessionType? sessionType,
    PractitionerInfo? practitioner,
    ClientInfo? client,
  }) = _Appointment;

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);
}

@freezed
class PractitionerInfo with _$PractitionerInfo {
  const factory PractitionerInfo({
    required String id,
    required UserInfo user,
    String? practiceName,
    String? postcode,
  }) = _PractitionerInfo;

  factory PractitionerInfo.fromJson(Map<String, dynamic> json) =>
      _$PractitionerInfoFromJson(json);
}

@freezed
class ClientInfo with _$ClientInfo {
  const factory ClientInfo({
    required String id,
    required UserInfo user,
  }) = _ClientInfo;

  factory ClientInfo.fromJson(Map<String, dynamic> json) =>
      _$ClientInfoFromJson(json);
}

@freezed
class UserInfo with _$UserInfo {
  const factory UserInfo({
    required String id,
    required String name,
    required String email,
    String? profilePhoto,
  }) = _UserInfo;

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
}

@freezed
class AvailableTimeSlot with _$AvailableTimeSlot {
  const factory AvailableTimeSlot({
    required DateTime startTime,
    required DateTime endTime,
    @Default(true) bool available,
  }) = _AvailableTimeSlot;

  factory AvailableTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$AvailableTimeSlotFromJson(json);
}
