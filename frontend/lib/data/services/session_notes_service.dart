import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/session_note.dart';
import 'package:sana_app/data/services/api_service.dart';

class SessionNotesService {
  final Dio dio;

  SessionNotesService(this.dio);

  // Create session note (practitioner only, after completed appointment)
  Future<SessionNote> createSessionNote({
    required String appointmentId,
    required String notes,
    String? privateNotes,
    String? recommendations,
    bool followUpRequired = false,
    DateTime? followUpDate,
  }) async {
    final response = await dio.post(
      '/session-notes',
      data: {
        'appointmentId': appointmentId,
        'notes': notes,
        if (privateNotes != null) 'privateNotes': privateNotes,
        if (recommendations != null) 'recommendations': recommendations,
        'followUpRequired': followUpRequired,
        if (followUpDate != null) 'followUpDate': followUpDate.toIso8601String(),
      },
    );
    return SessionNote.fromJson(response.data);
  }

  // Get all session notes for authenticated user
  Future<List<SessionNote>> getSessionNotes() async {
    final response = await dio.get('/session-notes');
    final List<dynamic> data = response.data ?? [];
    return data.map((note) => SessionNote.fromJson(note)).toList();
  }

  // Get single session note by ID
  Future<SessionNote> getSessionNoteById(String sessionNoteId) async {
    final response = await dio.get('/session-notes/$sessionNoteId');
    return SessionNote.fromJson(response.data);
  }

  // Update session note (practitioner only)
  Future<SessionNote> updateSessionNote({
    required String sessionNoteId,
    String? notes,
    String? privateNotes,
    String? recommendations,
    bool? followUpRequired,
    DateTime? followUpDate,
  }) async {
    final updateData = <String, dynamic>{};
    if (notes != null) updateData['notes'] = notes;
    if (privateNotes != null) updateData['privateNotes'] = privateNotes;
    if (recommendations != null) updateData['recommendations'] = recommendations;
    if (followUpRequired != null) updateData['followUpRequired'] = followUpRequired;
    if (followUpDate != null) updateData['followUpDate'] = followUpDate.toIso8601String();

    final response = await dio.put(
      '/session-notes/$sessionNoteId',
      data: updateData,
    );
    return SessionNote.fromJson(response.data);
  }

  // Delete session note (practitioner only)
  Future<Map<String, dynamic>> deleteSessionNote(String sessionNoteId) async {
    final response = await dio.delete('/session-notes/$sessionNoteId');
    return response.data;
  }
}

// Provider
final sessionNotesServiceProvider = Provider<SessionNotesService>((ref) {
  final dio = ref.watch(dioProvider);
  return SessionNotesService(dio);
});
