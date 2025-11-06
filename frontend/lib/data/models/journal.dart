import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal.freezed.dart';
part 'journal.g.dart';

// Journal Entry Model
@freezed
class JournalEntry with _\$JournalEntry {
  const factory JournalEntry({
    required String id,
    required String clientId,
    required String content,
    int? mood,
    @Default([]) List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _\$JournalEntryFromJson(json);
}

// Journal Statistics Model
@freezed
class JournalStats with _\$JournalStats {
  const factory JournalStats({
    required int totalEntries,
    required double averageMood,
    @Default([]) List<TagCount> mostUsedTags,
    @Default([]) List<MoodTrend> moodTrend,
    required int entriesThisWeek,
    required int entriesThisMonth,
  }) = _JournalStats;

  factory JournalStats.fromJson(Map<String, dynamic> json) =>
      _\$JournalStatsFromJson(json);
}

@freezed
class TagCount with _\$TagCount {
  const factory TagCount({
    required String tag,
    required int count,
  }) = _TagCount;

  factory TagCount.fromJson(Map<String, dynamic> json) =>
      _\$TagCountFromJson(json);
}

@freezed
class MoodTrend with _\$MoodTrend {
  const factory MoodTrend({
    required String date,
    required double mood,
  }) = _MoodTrend;

  factory MoodTrend.fromJson(Map<String, dynamic> json) =>
      _\$MoodTrendFromJson(json);
}

// Response Models
@freezed
class GetJournalEntriesResponse with _\$GetJournalEntriesResponse {
  const factory GetJournalEntriesResponse({
    required List<JournalEntry> entries,
    required int total,
  }) = _GetJournalEntriesResponse;

  factory GetJournalEntriesResponse.fromJson(Map<String, dynamic> json) =>
      _\$GetJournalEntriesResponseFromJson(json);
}
