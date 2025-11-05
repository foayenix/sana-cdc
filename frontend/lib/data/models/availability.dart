import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability.freezed.dart';
part 'availability.g.dart';

/// Day of week enum
enum DayOfWeek {
  @JsonValue('MONDAY')
  monday,
  @JsonValue('TUESDAY')
  tuesday,
  @JsonValue('WEDNESDAY')
  wednesday,
  @JsonValue('THURSDAY')
  thursday,
  @JsonValue('FRIDAY')
  friday,
  @JsonValue('SATURDAY')
  saturday,
  @JsonValue('SUNDAY')
  sunday,
}

/// Time off status enum
enum TimeOffStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

/// Availability slot (recurring weekly pattern)
@freezed
class AvailabilitySlot with _$AvailabilitySlot {
  const factory AvailabilitySlot({
    required String id,
    required String practitionerId,
    required DayOfWeek dayOfWeek,
    required String startTime,
    required String endTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? label,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AvailabilitySlot;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) =>
      _$AvailabilitySlotFromJson(json);
}

/// Time off request
@freezed
class TimeOff with _$TimeOff {
  const factory TimeOff({
    required String id,
    required String practitionerId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    @Default(TimeOffStatus.pending) TimeOffStatus status,
    String? approvedBy,
    DateTime? approvedAt,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TimeOff;

  factory TimeOff.fromJson(Map<String, dynamic> json) =>
      _$TimeOffFromJson(json);
}

/// Availability override for specific dates
@freezed
class AvailabilityOverride with _$AvailabilityOverride {
  const factory AvailabilityOverride({
    required String id,
    required String practitionerId,
    required DateTime date,
    String? startTime,
    String? endTime,
    String? reason,
    @Default(true) bool isAvailable,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AvailabilityOverride;

  factory AvailabilityOverride.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityOverrideFromJson(json);
}

/// Request to create availability slot
@freezed
class CreateAvailabilitySlotRequest with _$CreateAvailabilitySlotRequest {
  const factory CreateAvailabilitySlotRequest({
    required String practitionerId,
    required DayOfWeek dayOfWeek,
    required String startTime,
    required String endTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? label,
  }) = _CreateAvailabilitySlotRequest;

  factory CreateAvailabilitySlotRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAvailabilitySlotRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        'practitionerId': practitionerId,
        'dayOfWeek': dayOfWeek.name.toUpperCase(),
        'startTime': startTime,
        'endTime': endTime,
        if (effectiveFrom != null) 'effectiveFrom': effectiveFrom!.toIso8601String(),
        if (effectiveTo != null) 'effectiveTo': effectiveTo!.toIso8601String(),
        if (label != null) 'label': label,
      };
}

/// Request to update availability slot
@freezed
class UpdateAvailabilitySlotRequest with _$UpdateAvailabilitySlotRequest {
  const factory UpdateAvailabilitySlotRequest({
    DayOfWeek? dayOfWeek,
    String? startTime,
    String? endTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? label,
    bool? isActive,
  }) = _UpdateAvailabilitySlotRequest;

  factory UpdateAvailabilitySlotRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAvailabilitySlotRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek!.name.toUpperCase(),
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (effectiveFrom != null) 'effectiveFrom': effectiveFrom!.toIso8601String(),
        if (effectiveTo != null) 'effectiveTo': effectiveTo!.toIso8601String(),
        if (label != null) 'label': label,
        if (isActive != null) 'isActive': isActive,
      };
}

/// Request to create time off
@freezed
class CreateTimeOffRequest with _$CreateTimeOffRequest {
  const factory CreateTimeOffRequest({
    required String practitionerId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) = _CreateTimeOffRequest;

  factory CreateTimeOffRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTimeOffRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        'practitionerId': practitionerId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (reason != null) 'reason': reason,
      };
}

/// Request to create availability override
@freezed
class CreateAvailabilityOverrideRequest with _$CreateAvailabilityOverrideRequest {
  const factory CreateAvailabilityOverrideRequest({
    required String practitionerId,
    required DateTime date,
    String? startTime,
    String? endTime,
    String? reason,
    @Default(true) bool isAvailable,
  }) = _CreateAvailabilityOverrideRequest;

  factory CreateAvailabilityOverrideRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAvailabilityOverrideRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        'practitionerId': practitionerId,
        'date': date.toIso8601String(),
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (reason != null) 'reason': reason,
        'isAvailable': isAvailable,
      };
}

/// Helper extensions
extension DayOfWeekExtension on DayOfWeek {
  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String get shortName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }
}

extension TimeOffStatusExtension on TimeOffStatus {
  String get displayName {
    switch (this) {
      case TimeOffStatus.pending:
        return 'Pending';
      case TimeOffStatus.approved:
        return 'Approved';
      case TimeOffStatus.rejected:
        return 'Rejected';
    }
  }
}
