import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics.freezed.dart';
part 'analytics.g.dart';

/// Client analytics overview
@freezed
class ClientAnalyticsOverview with _$ClientAnalyticsOverview {
  const factory ClientAnalyticsOverview({
    required int totalAppointments,
    required int completedAppointments,
    required int upcomingAppointments,
    required int cancelledAppointments,
    required double totalSpent,
    required double averageOutcomeScore,
    required double currentSanaIndex,
  }) = _ClientAnalyticsOverview;

  factory ClientAnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      _$ClientAnalyticsOverviewFromJson(json);
}

/// Practitioner analytics overview
@freezed
class PractitionerAnalyticsOverview with _$PractitionerAnalyticsOverview {
  const factory PractitionerAnalyticsOverview({
    required int totalAppointments,
    required int completedAppointments,
    required int upcomingAppointments,
    required int cancelledAppointments,
    required double totalEarnings,
    required int totalClients,
    required double repeatClientRate,
  }) = _PractitionerAnalyticsOverview;

  factory PractitionerAnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      _$PractitionerAnalyticsOverviewFromJson(json);
}

/// SANA Index progression data point
@freezed
class SanaIndexDataPoint with _$SanaIndexDataPoint {
  const factory SanaIndexDataPoint({
    required double score,
    required DateTime date,
  }) = _SanaIndexDataPoint;

  factory SanaIndexDataPoint.fromJson(Map<String, dynamic> json) =>
      _$SanaIndexDataPointFromJson(json);
}

/// Session type distribution
@freezed
class SessionTypeDistribution with _$SessionTypeDistribution {
  const factory SessionTypeDistribution({
    required String name,
    required int count,
    required double percentage,
  }) = _SessionTypeDistribution;

  factory SessionTypeDistribution.fromJson(Map<String, dynamic> json) =>
      _$SessionTypeDistributionFromJson(json);
}

/// Monthly trend data point
@freezed
class MonthlyTrendDataPoint with _$MonthlyTrendDataPoint {
  const factory MonthlyTrendDataPoint({
    required String month,
    required int count,
  }) = _MonthlyTrendDataPoint;

  factory MonthlyTrendDataPoint.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTrendDataPointFromJson(json);
}

/// Monthly revenue data point
@freezed
class MonthlyRevenueDataPoint with _$MonthlyRevenueDataPoint {
  const factory MonthlyRevenueDataPoint({
    required String month,
    required double revenue,
    required int count,
  }) = _MonthlyRevenueDataPoint;

  factory MonthlyRevenueDataPoint.fromJson(Map<String, dynamic> json) =>
      _$MonthlyRevenueDataPointFromJson(json);
}

/// Top client
@freezed
class TopClient with _$TopClient {
  const factory TopClient({
    required String clientId,
    required String clientName,
    required int appointmentCount,
  }) = _TopClient;

  factory TopClient.fromJson(Map<String, dynamic> json) =>
      _$TopClientFromJson(json);
}

/// Upcoming appointment summary
@freezed
class UpcomingAppointmentSummary with _$UpcomingAppointmentSummary {
  const factory UpcomingAppointmentSummary({
    required String id,
    required String clientName,
    required String sessionType,
    required DateTime appointmentDate,
    required String status,
  }) = _UpcomingAppointmentSummary;

  factory UpcomingAppointmentSummary.fromJson(Map<String, dynamic> json) =>
      _$UpcomingAppointmentSummaryFromJson(json);
}

/// Date range
@freezed
class DateRange with _$DateRange {
  const factory DateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) = _DateRange;

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);
}

/// Client analytics response
@freezed
class ClientAnalytics with _$ClientAnalytics {
  const factory ClientAnalytics({
    required ClientAnalyticsOverview overview,
    required List<SanaIndexDataPoint> sanaIndexProgression,
    required List<SessionTypeDistribution> sessionTypeDistribution,
    required List<MonthlyTrendDataPoint> monthlyTrend,
    required DateRange dateRange,
  }) = _ClientAnalytics;

  factory ClientAnalytics.fromJson(Map<String, dynamic> json) =>
      _$ClientAnalyticsFromJson(json);
}

/// Practitioner analytics response
@freezed
class PractitionerAnalytics with _$PractitionerAnalytics {
  const factory PractitionerAnalytics({
    required PractitionerAnalyticsOverview overview,
    required List<SessionTypeDistribution> sessionTypeDistribution,
    required List<MonthlyRevenueDataPoint> monthlyRevenue,
    required List<TopClient> topClients,
    required List<UpcomingAppointmentSummary> upcomingAppointments,
    required DateRange dateRange,
  }) = _PractitionerAnalytics;

  factory PractitionerAnalytics.fromJson(Map<String, dynamic> json) =>
      _$PractitionerAnalyticsFromJson(json);
}
