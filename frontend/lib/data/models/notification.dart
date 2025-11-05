import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// Notification types
enum NotificationType {
  @JsonValue('APPOINTMENT_CONFIRMATION')
  appointmentConfirmation,
  @JsonValue('APPOINTMENT_REMINDER_24H')
  appointmentReminder24h,
  @JsonValue('APPOINTMENT_REMINDER_1H')
  appointmentReminder1h,
  @JsonValue('APPOINTMENT_CANCELLED')
  appointmentCancelled,
  @JsonValue('APPOINTMENT_RESCHEDULED')
  appointmentRescheduled,
  @JsonValue('PAYMENT_SUCCESS')
  paymentSuccess,
  @JsonValue('PAYMENT_FAILED')
  paymentFailed,
  @JsonValue('PAYMENT_REFUNDED')
  paymentRefunded,
  @JsonValue('SESSION_NOTE_ADDED')
  sessionNoteAdded,
  @JsonValue('OUTCOME_RECORDED')
  outcomeRecorded,
  @JsonValue('PRACTITIONER_VERIFIED')
  practitionerVerified,
  @JsonValue('PRACTITIONER_REJECTED')
  practitionerRejected,
  @JsonValue('NEW_MESSAGE')
  newMessage,
  @JsonValue('REVIEW_RECEIVED')
  reviewReceived,
  @JsonValue('SYSTEM_ANNOUNCEMENT')
  systemAnnouncement,
}

/// Notification model
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    @Default(false) bool read,
    DateTime? readAt,
    @Default(false) bool sent,
    DateTime? sentAt,
    @Default(false) bool emailSent,
    @Default(false) bool smsSent,
    @Default(false) bool pushSent,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

/// Notification list response
@freezed
class NotificationListResponse with _$NotificationListResponse {
  const factory NotificationListResponse({
    required List<AppNotification> notifications,
    required int total,
    required int unreadCount,
  }) = _NotificationListResponse;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseFromJson(json);
}

/// Unread count response
@freezed
class UnreadCountResponse with _$UnreadCountResponse {
  const factory UnreadCountResponse({
    required int unreadCount,
  }) = _UnreadCountResponse;

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseFromJson(json);
}

/// Notification preference model
@freezed
class NotificationPreference with _$NotificationPreference {
  const factory NotificationPreference({
    required String id,
    required String userId,
    // Channel preferences
    @Default(true) bool emailEnabled,
    @Default(false) bool smsEnabled,
    @Default(true) bool pushEnabled,
    // Type preferences
    @Default(true) bool appointmentReminders,
    @Default(true) bool appointmentUpdates,
    @Default(true) bool paymentNotifications,
    @Default(true) bool sessionNotes,
    @Default(true) bool outcomeNotifications,
    @Default(true) bool messageNotifications,
    @Default(false) bool promotionalEmails,
    @Default(true) bool systemAnnouncements,
    String? phoneNumber,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationPreference;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceFromJson(json);
}

/// Update notification preference request
@freezed
class UpdateNotificationPreferenceRequest
    with _$UpdateNotificationPreferenceRequest {
  const factory UpdateNotificationPreferenceRequest({
    bool? emailEnabled,
    bool? smsEnabled,
    bool? pushEnabled,
    bool? appointmentReminders,
    bool? appointmentUpdates,
    bool? paymentNotifications,
    bool? sessionNotes,
    bool? outcomeNotifications,
    bool? messageNotifications,
    bool? promotionalEmails,
    bool? systemAnnouncements,
    String? phoneNumber,
  }) = _UpdateNotificationPreferenceRequest;

  factory UpdateNotificationPreferenceRequest.fromJson(
          Map<String, dynamic> json) =>
      _$UpdateNotificationPreferenceRequestFromJson(json);
}
