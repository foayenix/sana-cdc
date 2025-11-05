import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/notification.dart';
import 'package:sana_app/core/network/dio_client.dart';

/// Notifications service for API communication
class NotificationsService {
  final Dio _dio;

  NotificationsService(this._dio);

  /// Get user's notifications
  Future<NotificationListResponse> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return NotificationListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      final result = UnreadCountResponse.fromJson(response.data);
      return result.unreadCount;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark notification as read
  Future<AppNotification> markAsRead(String notificationId) async {
    try {
      final response = await _dio.put('/notifications/$notificationId/read');
      return AppNotification.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get notification preferences
  Future<NotificationPreference> getPreferences() async {
    try {
      final response = await _dio.get('/notifications/preferences');
      return NotificationPreference.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update notification preferences
  Future<NotificationPreference> updatePreferences(
    UpdateNotificationPreferenceRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/notifications/preferences',
        data: request.toJson(),
      );
      return NotificationPreference.fromJson(response.data);
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

/// Provider for NotificationsService
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return NotificationsService(dio);
});

/// Provider for notification list
final notificationListProvider =
    FutureProvider.family<NotificationListResponse, int>((ref, offset) async {
  final service = ref.watch(notificationsServiceProvider);
  return service.getNotifications(limit: 50, offset: offset);
});

/// Provider for unread count
final unreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationsServiceProvider);
  return service.getUnreadCount();
});

/// Provider for notification preferences
final notificationPreferencesProvider =
    FutureProvider<NotificationPreference>((ref) async {
  final service = ref.watch(notificationsServiceProvider);
  return service.getPreferences();
});

/// State notifier for managing notifications
class NotificationsNotifier
    extends StateNotifier<AsyncValue<NotificationListResponse>> {
  final NotificationsService _service;
  int _currentOffset = 0;

  NotificationsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  /// Load notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      state = const AsyncValue.loading();
    }

    try {
      final result = await _service.getNotifications(
        limit: 50,
        offset: _currentOffset,
      );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load more notifications
  Future<void> loadMore() async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final currentData = currentState.value!;
    if (currentData.notifications.length >= currentData.total) return;

    _currentOffset += 50;

    try {
      final result = await _service.getNotifications(
        limit: 50,
        offset: _currentOffset,
      );

      state = AsyncValue.data(
        NotificationListResponse(
          notifications: [
            ...currentData.notifications,
            ...result.notifications,
          ],
          total: result.total,
          unreadCount: result.unreadCount,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      await loadNotifications(refresh: true);
    } catch (error) {
      // Handle error silently or show a message
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      await loadNotifications(refresh: true);
    } catch (error) {
      // Handle error silently or show a message
    }
  }
}

/// Provider for notifications notifier
final notificationsNotifierProvider = StateNotifierProvider<
    NotificationsNotifier, AsyncValue<NotificationListResponse>>((ref) {
  final service = ref.watch(notificationsServiceProvider);
  return NotificationsNotifier(service);
});
