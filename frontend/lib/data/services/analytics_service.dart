import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/analytics.dart';
import 'package:sana_app/core/network/dio_client.dart';

/// Analytics service for API communication
class AnalyticsService {
  final Dio _dio;

  AnalyticsService(this._dio);

  /// Get client analytics
  Future<ClientAnalytics> getClientAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/analytics/client',
        queryParameters: queryParams,
      );
      return ClientAnalytics.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get practitioner analytics
  Future<PractitionerAnalytics> getPractitionerAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/analytics/practitioner',
        queryParameters: queryParams,
      );
      return PractitionerAnalytics.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AnalyticsService(dio);
});

/// Provider for client analytics (with date range)
final clientAnalyticsProvider = FutureProvider.family<ClientAnalytics,
    ({DateTime? startDate, DateTime? endDate})>((ref, dateRange) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getClientAnalytics(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );
});

/// Provider for practitioner analytics (with date range)
final practitionerAnalyticsProvider = FutureProvider.family<
    PractitionerAnalytics,
    ({DateTime? startDate, DateTime? endDate})>((ref, dateRange) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getPractitionerAnalytics(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );
});
