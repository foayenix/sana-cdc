import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_note.freezed.dart';
part 'session_note.g.dart';

@freezed
class SessionNote with _$SessionNote {
  const factory SessionNote({
    required String id,
    required String appointmentId,
    required String notes,
    String? privateNotes, // Only visible to practitioner
    String? recommendations,
    @Default(false) bool followUpRequired,
    DateTime? followUpDate,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _SessionNote;

  factory SessionNote.fromJson(Map<String, dynamic> json) =>
      _$SessionNoteFromJson(json);
}

@freezed
class CreateSessionNoteRequest with _$CreateSessionNoteRequest {
  const factory CreateSessionNoteRequest({
    required String appointmentId,
    required String notes,
    String? privateNotes,
    String? recommendations,
    @Default(false) bool followUpRequired,
    DateTime? followUpDate,
  }) = _CreateSessionNoteRequest;

  factory CreateSessionNoteRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSessionNoteRequestFromJson(json);
}
