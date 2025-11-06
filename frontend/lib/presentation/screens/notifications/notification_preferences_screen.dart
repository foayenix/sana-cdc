import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/notification.dart';
import 'package:sana_app/data/services/notifications_service.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _isSaving = false;
  NotificationPreference? _preferences;

  // Local state for switches
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _pushEnabled = true;
  bool _appointmentReminders = true;
  bool _appointmentUpdates = true;
  bool _paymentNotifications = true;
  bool _sessionNotes = true;
  bool _outcomeNotifications = true;
  bool _messageNotifications = true;
  bool _promotionalEmails = false;
  bool _systemAnnouncements = true;
  String? _phoneNumber;

  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(notificationsServiceProvider);
      final request = UpdateNotificationPreferenceRequest(
        emailEnabled: _emailEnabled,
        smsEnabled: _smsEnabled,
        pushEnabled: _pushEnabled,
        appointmentReminders: _appointmentReminders,
        appointmentUpdates: _appointmentUpdates,
        paymentNotifications: _paymentNotifications,
        sessionNotes: _sessionNotes,
        outcomeNotifications: _outcomeNotifications,
        messageNotifications: _messageNotifications,
        promotionalEmails: _promotionalEmails,
        systemAnnouncements: _systemAnnouncements,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      await service.updatePreferences(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _loadPreferences(NotificationPreference prefs) {
    if (_preferences != null) return; // Only load once

    setState(() {
      _preferences = prefs;
      _emailEnabled = prefs.emailEnabled;
      _smsEnabled = prefs.smsEnabled;
      _pushEnabled = prefs.pushEnabled;
      _appointmentReminders = prefs.appointmentReminders;
      _appointmentUpdates = prefs.appointmentUpdates;
      _paymentNotifications = prefs.paymentNotifications;
      _sessionNotes = prefs.sessionNotes;
      _outcomeNotifications = prefs.outcomeNotifications;
      _messageNotifications = prefs.messageNotifications;
      _promotionalEmails = prefs.promotionalEmails;
      _systemAnnouncements = prefs.systemAnnouncements;
      _phoneNumber = prefs.phoneNumber;
      _phoneController.text = prefs.phoneNumber ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (_preferences != null)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: preferencesAsync.when(
        data: (prefs) {
          _loadPreferences(prefs);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Channel preferences section
              _buildSectionHeader('Delivery Channels'),
              const SizedBox(height: 8),
              _buildChannelCard(),
              const SizedBox(height: 24),

              // Notification types section
              _buildSectionHeader('Notification Types'),
              const SizedBox(height: 8),
              _buildNotificationTypesCard(),
              const SizedBox(height: 24),

              // SMS phone number (only show if SMS is enabled)
              if (_smsEnabled) ...[
                _buildSectionHeader('SMS Settings'),
                const SizedBox(height: 8),
                _buildPhoneNumberCard(),
                const SizedBox(height: 24),
              ],

              // Info section
              _buildInfoCard(),
            ],
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
              const Text(
                'Failed to load preferences',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(notificationPreferencesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildChannelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSwitchTile(
              icon: Icons.email,
              iconColor: Colors.blue,
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _emailEnabled,
              onChanged: (value) {
                setState(() {
                  _emailEnabled = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.sms,
              iconColor: Colors.green,
              title: 'SMS Notifications',
              subtitle: 'Receive urgent notifications via SMS',
              value: _smsEnabled,
              onChanged: (value) {
                setState(() {
                  _smsEnabled = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.notifications,
              iconColor: Colors.orange,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications on your device',
              value: _pushEnabled,
              onChanged: (value) {
                setState(() {
                  _pushEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSwitchTile(
              icon: Icons.alarm,
              iconColor: Colors.orange,
              title: 'Appointment Reminders',
              subtitle: '24-hour and 1-hour reminders',
              value: _appointmentReminders,
              onChanged: (value) {
                setState(() {
                  _appointmentReminders = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.event,
              iconColor: Colors.blue,
              title: 'Appointment Updates',
              subtitle: 'Confirmations, cancellations, and changes',
              value: _appointmentUpdates,
              onChanged: (value) {
                setState(() {
                  _appointmentUpdates = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.payment,
              iconColor: Colors.green,
              title: 'Payment Notifications',
              subtitle: 'Payment confirmations and receipts',
              value: _paymentNotifications,
              onChanged: (value) {
                setState(() {
                  _paymentNotifications = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.note,
              iconColor: Colors.purple,
              title: 'Session Notes',
              subtitle: 'When practitioners add session notes',
              value: _sessionNotes,
              onChanged: (value) {
                setState(() {
                  _sessionNotes = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.analytics,
              iconColor: Colors.teal,
              title: 'Outcome Notifications',
              subtitle: 'Progress and outcome updates',
              value: _outcomeNotifications,
              onChanged: (value) {
                setState(() {
                  _outcomeNotifications = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.message,
              iconColor: Colors.indigo,
              title: 'Message Notifications',
              subtitle: 'New messages from practitioners',
              value: _messageNotifications,
              onChanged: (value) {
                setState(() {
                  _messageNotifications = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.campaign,
              iconColor: Colors.amber,
              title: 'System Announcements',
              subtitle: 'Important platform updates',
              value: _systemAnnouncements,
              onChanged: (value) {
                setState(() {
                  _systemAnnouncements = value;
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              icon: Icons.local_offer,
              iconColor: Colors.pink,
              title: 'Promotional Emails',
              subtitle: 'Tips, offers, and wellness content',
              value: _promotionalEmails,
              onChanged: (value) {
                setState(() {
                  _promotionalEmails = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Enter phone number for SMS',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                helperText: 'Include country code (e.g., +44 7700 900000)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can customize how you receive notifications. Even if you turn off certain types, critical notifications (like appointment reminders) may still be sent to ensure you don\'t miss important updates.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
