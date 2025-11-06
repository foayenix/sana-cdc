import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sana_app/data/models/notification.dart';
import 'package:sana_app/data/services/notifications_service.dart';
import 'package:sana_app/core/constants/app_constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  ConsumerState<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState
    extends ConsumerState<NotificationsListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await ref.read(notificationsNotifierProvider.notifier).loadMore();

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(notificationsNotifierProvider.notifier)
        .loadNotifications(refresh: true);
  }

  Future<void> _markAsRead(String notificationId) async {
    await ref
        .read(notificationsNotifierProvider.notifier)
        .markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    await ref.read(notificationsNotifierProvider.notifier).markAllAsRead();
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    if (!notification.read) {
      _markAsRead(notification.id);
    }

    // Navigate based on notification type
    _navigateToRelevantScreen(notification);
  }

  void _navigateToRelevantScreen(AppNotification notification) {
    final data = notification.data;

    switch (notification.type) {
      case NotificationType.appointmentConfirmation:
      case NotificationType.appointmentReminder24h:
      case NotificationType.appointmentReminder1h:
      case NotificationType.appointmentCancelled:
      case NotificationType.appointmentRescheduled:
        // Navigate to appointments list (detail view not yet implemented)
        context.push(AppConstants.routeAppointments);
        break;

      case NotificationType.paymentSuccess:
      case NotificationType.paymentFailed:
      case NotificationType.paymentRefunded:
        context.push(AppConstants.routePaymentHistory);
        break;

      case NotificationType.sessionNoteAdded:
        // Navigate to appointments list (detail view not yet implemented)
        context.push(AppConstants.routeAppointments);
        break;

      case NotificationType.outcomeRecorded:
        context.push(AppConstants.routeDashboard);
        break;

      case NotificationType.practitionerVerified:
      case NotificationType.practitionerRejected:
        context.push(AppConstants.routeProfile);
        break;

      case NotificationType.newMessage:
        // TODO: Navigate to messages screen when implemented
        break;

      case NotificationType.reviewReceived:
        // TODO: Navigate to reviews screen when implemented
        break;

      case NotificationType.systemAnnouncement:
        // Stay on notifications screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsState.when(
            data: (data) {
              if (data.unreadCount > 0) {
                return TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppConstants.routeNotificationPreferences);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: notificationsState.when(
          data: (data) {
            if (data.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you have notifications,\nthey will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: data.notifications.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == data.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final notification = data.notifications[index];
                return _buildNotificationCard(notification);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load notifications',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final icon = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationIconColor(notification.type);
    final timeAgo = timeago.format(notification.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.read ? 0 : 2,
      color: notification.read ? null : Theme.of(context).primaryColor.withOpacity(0.05),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.read
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (notification.emailSent) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.email,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                        ],
                        if (notification.pushSent) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.notifications,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmation:
        return Icons.check_circle;
      case NotificationType.appointmentReminder24h:
      case NotificationType.appointmentReminder1h:
        return Icons.alarm;
      case NotificationType.appointmentCancelled:
        return Icons.cancel;
      case NotificationType.appointmentRescheduled:
        return Icons.update;
      case NotificationType.paymentSuccess:
        return Icons.payment;
      case NotificationType.paymentFailed:
      case NotificationType.paymentRefunded:
        return Icons.error;
      case NotificationType.sessionNoteAdded:
        return Icons.note_add;
      case NotificationType.outcomeRecorded:
        return Icons.analytics;
      case NotificationType.practitionerVerified:
        return Icons.verified_user;
      case NotificationType.practitionerRejected:
        return Icons.person_off;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.systemAnnouncement:
        return Icons.campaign;
    }
  }

  Color _getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmation:
      case NotificationType.practitionerVerified:
      case NotificationType.paymentSuccess:
        return Colors.green;
      case NotificationType.appointmentReminder24h:
      case NotificationType.appointmentReminder1h:
        return Colors.orange;
      case NotificationType.appointmentCancelled:
      case NotificationType.practitionerRejected:
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.appointmentRescheduled:
        return Colors.blue;
      case NotificationType.paymentRefunded:
        return Colors.amber;
      case NotificationType.sessionNoteAdded:
      case NotificationType.outcomeRecorded:
        return Colors.purple;
      case NotificationType.newMessage:
        return Colors.teal;
      case NotificationType.reviewReceived:
        return Colors.amber;
      case NotificationType.systemAnnouncement:
        return Colors.indigo;
    }
  }
}
