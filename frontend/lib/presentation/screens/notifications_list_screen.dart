import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/core/constants/app_constants.dart';
import 'package:sana_app/data/models/notification.dart';
import 'package:sana_app/data/services/notifications_service.dart';

class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsNotifierProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Unread badge
          unreadCountAsync.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              _showMarkAllAsReadDialog(context, ref);
            },
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Notification settings',
            onPressed: () {
              context.push('/notification-preferences');
            },
          ),
        ],
      ),
      body: notificationsState.when(
        data: (response) {
          if (response.notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(notificationsNotifierProvider.notifier)
                  .loadNotifications(refresh: true);
            },
            child: ListView.builder(
              itemCount: response.notifications.length + 1,
              itemBuilder: (context, index) {
                if (index == response.notifications.length) {
                  // Load more button
                  if (response.notifications.length < response.total) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(notificationsNotifierProvider.notifier)
                                .loadMore();
                          },
                          child: const Text('Load More'),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final notification = response.notifications[index];
                return _buildNotificationCard(context, ref, notification);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(notificationsNotifierProvider.notifier)
                      .loadNotifications(refresh: true);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see your notifications here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    final theme = Theme.of(context);
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        await ref
            .read(notificationsNotifierProvider.notifier)
            .markAsRead(notification.id);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: notification.read ? 0 : 2,
        color: notification.read ? null : color.withOpacity(0.05),
        child: InkWell(
          onTap: () {
            _handleNotificationTap(context, ref, notification);
          },
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
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
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
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
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
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmation:
      case NotificationType.appointmentReminder24h:
      case NotificationType.appointmentReminder1h:
        return Icons.calendar_today;
      case NotificationType.appointmentCancelled:
        return Icons.event_busy;
      case NotificationType.appointmentRescheduled:
        return Icons.update;
      case NotificationType.paymentSuccess:
        return Icons.check_circle;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.paymentRefunded:
        return Icons.money_off;
      case NotificationType.sessionNoteAdded:
        return Icons.note_add;
      case NotificationType.outcomeRecorded:
        return Icons.assessment;
      case NotificationType.practitionerVerified:
        return Icons.verified;
      case NotificationType.practitionerRejected:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.systemAnnouncement:
        return Icons.announcement;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmation:
      case NotificationType.paymentSuccess:
      case NotificationType.practitionerVerified:
        return Colors.green;
      case NotificationType.appointmentReminder24h:
      case NotificationType.appointmentReminder1h:
      case NotificationType.appointmentRescheduled:
        return Colors.orange;
      case NotificationType.appointmentCancelled:
      case NotificationType.paymentFailed:
      case NotificationType.practitionerRejected:
        return Colors.red;
      case NotificationType.sessionNoteAdded:
      case NotificationType.outcomeRecorded:
        return Colors.blue;
      case NotificationType.newMessage:
      case NotificationType.reviewReceived:
        return Colors.purple;
      case NotificationType.paymentRefunded:
      case NotificationType.systemAnnouncement:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Mark as read
    if (!notification.read) {
      ref
          .read(notificationsNotifierProvider.notifier)
          .markAsRead(notification.id);
    }

    // Navigate based on notification type
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.appointmentConfirmation:
      case NotificationType.appointmentReminder24h:
      case NotificationType.appointmentReminder1h:
      case NotificationType.appointmentCancelled:
      case NotificationType.appointmentRescheduled:
      case NotificationType.sessionNoteAdded:
        final appointmentId = data['appointmentId'] as String?;
        if (appointmentId != null) {
          context.push('/appointments/$appointmentId');
        }
        break;
      case NotificationType.paymentSuccess:
      case NotificationType.paymentFailed:
      case NotificationType.paymentRefunded:
        context.push(AppConstants.routeAppointments);
        break;
      case NotificationType.outcomeRecorded:
        context.push(AppConstants.routeOutcomes);
        break;
      default:
        break;
    }
  }

  void _showMarkAllAsReadDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark all as read'),
        content: const Text(
          'Are you sure you want to mark all notifications as read?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationsNotifierProvider.notifier).markAllAsRead();
              Navigator.of(context).pop();
            },
            child: const Text('Mark All'),
          ),
        ],
      ),
    );
  }
}
