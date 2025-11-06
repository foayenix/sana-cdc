import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal.dart';
import '../../core/constants/api_constants.dart';

final journalServiceProvider = Provider<JournalService>((ref) {
  return JournalService();
});

class JournalService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer \$token';
  }

  // Create journal entry
  Future<JournalEntry> createEntry({
    required String content,
    int? mood,
    List<String>? tags,
  }) async {
    try {
      final response = await _dio.post(
        '/journal',
        data: {
          'content': content,
          if (mood != null) 'mood': mood,
          if (tags != null) 'tags': tags,
        },
      );
      return JournalEntry.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get journal entries
  Future<GetJournalEntriesResponse> getEntries({
    List<String>? tags,
    int? mood,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
      if (mood != null) queryParams['mood'] = mood;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '/journal',
        queryParameters: queryParams,
      );

      return GetJournalEntriesResponse.fromJson({
        'entries': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get journal entry by ID
  Future<JournalEntry> getEntryById(String id) async {
    try {
      final response = await _dio.get('/journal/\$id');
      return JournalEntry.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Update journal entry
  Future<JournalEntry> updateEntry({
    required String id,
    String? content,
    int? mood,
    List<String>? tags,
  }) async {
    try {
      final response = await _dio.put(
        '/journal/\$id',
        data: {
          if (content != null) 'content': content,
          if (mood != null) 'mood': mood,
          if (tags != null) 'tags': tags,
        },
      );
      return JournalEntry.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Delete journal entry
  Future<void> deleteEntry(String id) async {
    try {
      await _dio.delete('/journal/\$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get journal statistics
  Future<JournalStats> getStats() async {
    try {
      final response = await _dio.get('/journal/stats');
      return JournalStats.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Search journal entries
  Future<List<JournalEntry>> searchEntries({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/journal/search',
        queryParameters: {
          'q': query,
          'limit': limit,
        },
      );
      return (response.data['data'] as List)
          .map((json) => JournalEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get unique tags
  Future<List<String>> getUniqueTags() async {
    try {
      final response = await _dio.get('/journal/tags');
      return List<String>.from(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        return e.response?.data['message'] ?? 'An error occurred';
      }
      return 'Network error. Please check your connection.';
    }
    return 'An unexpected error occurred';
  }

  // Helper methods
  static String formatDate(DateTime date) {
    return '\${date.day}/\${date.month}/\${date.year}';
  }

  static String formatDateTime(DateTime date) {
    return '\${date.day}/\${date.month}/\${date.year} \${date.hour}:\${date.minute.toString().padLeft(2, '0')}';
  }

  static String getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }

  static String getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Unknown';
    }
  }
}

// State Management with Riverpod

// Journal Entries State
class JournalEntriesState {
  final List<JournalEntry> entries;
  final int total;
  final bool isLoading;
  final String? error;
  final JournalStats? stats;

  JournalEntriesState({
    this.entries = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.stats,
  });

  JournalEntriesState copyWith({
    List<JournalEntry>? entries,
    int? total,
    bool? isLoading,
    String? error,
    JournalStats? stats,
  }) {
    return JournalEntriesState(
      entries: entries ?? this.entries,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

class JournalEntriesNotifier extends StateNotifier<JournalEntriesState> {
  final JournalService _journalService;

  JournalEntriesNotifier(this._journalService) : super(JournalEntriesState());

  Future<void> loadEntries({
    List<String>? tags,
    int? mood,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _journalService.getEntries(
        tags: tags,
        mood: mood,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        entries: offset == 0
            ? response.entries
            : [...state.entries, ...response.entries],
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _journalService.getStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createEntry({
    required String content,
    int? mood,
    List<String>? tags,
  }) async {
    try {
      final entry = await _journalService.createEntry(
        content: content,
        mood: mood,
        tags: tags,
      );
      state = state.copyWith(
        entries: [entry, ...state.entries],
        total: state.total + 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateEntry({
    required String id,
    String? content,
    int? mood,
    List<String>? tags,
  }) async {
    try {
      final updatedEntry = await _journalService.updateEntry(
        id: id,
        content: content,
        mood: mood,
        tags: tags,
      );
      state = state.copyWith(
        entries: state.entries.map((e) {
          if (e.id == id) {
            return updatedEntry;
          }
          return e;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _journalService.deleteEntry(id);
      state = state.copyWith(
        entries: state.entries.where((e) => e.id != id).toList(),
        total: state.total - 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void refresh() => loadEntries();
}

final journalEntriesProvider =
    StateNotifierProvider<JournalEntriesNotifier, JournalEntriesState>((ref) {
  final journalService = ref.watch(journalServiceProvider);
  return JournalEntriesNotifier(journalService);
});
