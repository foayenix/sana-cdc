import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Message in a conversation
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String receiverId,
    String? text,
    String? attachmentUrl,
    String? attachmentType,
    @Default(false) bool read,
    DateTime? readAt,
    @Default(false) bool isSystemMessage,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
    MessageSender? sender,
    MessageSender? receiver,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// Message sender/receiver info
@freezed
class MessageSender with _$MessageSender {
  const factory MessageSender({
    required String id,
    required String name,
    String? profilePhoto,
  }) = _MessageSender;

  factory MessageSender.fromJson(Map<String, dynamic> json) =>
      _$MessageSenderFromJson(json);
}

/// Conversation between client and practitioner
@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String clientId,
    required String practitionerId,
    String? appointmentId,
    String? lastMessageText,
    DateTime? lastMessageAt,
    @Default(0) int clientUnread,
    @Default(0) int practitionerUnread,
    @Default(false) bool clientArchived,
    @Default(false) bool practitionerArchived,
    required DateTime createdAt,
    required DateTime updatedAt,
    ConversationUser? client,
    ConversationUser? practitioner,
    List<Message>? messages,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

/// Conversation user info
@freezed
class ConversationUser with _$ConversationUser {
  const factory ConversationUser({
    required String id,
    required String name,
    required String email,
    String? profilePhoto,
  }) = _ConversationUser;

  factory ConversationUser.fromJson(Map<String, dynamic> json) =>
      _$ConversationUserFromJson(json);
}

/// Request to create a conversation
@freezed
class CreateConversationRequest with _$CreateConversationRequest {
  const factory CreateConversationRequest({
    required String clientId,
    required String practitionerId,
    String? appointmentId,
  }) = _CreateConversationRequest;

  factory CreateConversationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'practitionerId': practitionerId,
        if (appointmentId != null) 'appointmentId': appointmentId,
      };
}

/// Request to send a message
@freezed
class SendMessageRequest with _$SendMessageRequest {
  const factory SendMessageRequest({
    required String conversationId,
    required String senderId,
    String? text,
    String? attachmentUrl,
    String? attachmentType,
    @Default(false) bool isSystemMessage,
    Map<String, dynamic>? metadata,
  }) = _SendMessageRequest;

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'senderId': senderId,
        if (text != null) 'text': text,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (attachmentType != null) 'attachmentType': attachmentType,
        'isSystemMessage': isSystemMessage,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Conversations list response
@freezed
class ConversationsResponse with _$ConversationsResponse {
  const factory ConversationsResponse({
    required List<Conversation> conversations,
    required int total,
  }) = _ConversationsResponse;

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationsResponseFromJson(json);
}

/// Messages list response
@freezed
class MessagesResponse with _$MessagesResponse {
  const factory MessagesResponse({
    required List<Message> messages,
    required int total,
  }) = _MessagesResponse;

  factory MessagesResponse.fromJson(Map<String, dynamic> json) =>
      _$MessagesResponseFromJson(json);
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

/// Typing status
@freezed
class TypingStatus with _$TypingStatus {
  const factory TypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) = _TypingStatus;

  factory TypingStatus.fromJson(Map<String, dynamic> json) =>
      _$TypingStatusFromJson(json);
}
