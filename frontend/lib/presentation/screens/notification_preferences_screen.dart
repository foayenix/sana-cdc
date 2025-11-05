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
  bool _isLoading = false;
  bool _isSaving = false;

  // Channel preferences
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _pushEnabled = true;

  // Type preferences
  bool _appointmentReminders = true;
  bool _appointmentUpdates = true;
  bool _paymentNotifications = true;
  bool _sessionNotes = true;
  bool _outcomeNotifications = true;
  bool _messageNotifications = true;
  bool _promotionalEmails = false;
  bool _systemAnnouncements = true;

  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(notificationsServiceProvider);
      final prefs = await service.getPreferences();

      setState(() {
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preferences: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      final service = ref.read(notificationsServiceProvider);
      await service.updatePreferences(
        UpdateNotificationPreferenceRequest(
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
          phoneNumber: _phoneNumber,
        ),
      );

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save preferences',
              onPressed: _savePreferences,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Channels Section
                _buildSectionHeader('Notification Channels'),
                _buildSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  icon: Icons.email,
                  value: _emailEnabled,
                  onChanged: (value) => setState(() => _emailEnabled = value),
                ),
                _buildSwitchTile(
                  title: 'SMS Notifications',
                  subtitle: 'Receive notifications via SMS',
                  icon: Icons.sms,
                  value: _smsEnabled,
                  onChanged: (value) => setState(() => _smsEnabled = value),
                ),
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications on your device',
                  icon: Icons.notifications_active,
                  value: _pushEnabled,
                  onChanged: (value) => setState(() => _pushEnabled = value),
                ),

                const Divider(height: 32),

                // Notification Types Section
                _buildSectionHeader('Notification Types'),
                _buildSwitchTile(
                  title: 'Appointment Reminders',
                  subtitle: '24h and 1h before appointments',
                  icon: Icons.alarm,
                  value: _appointmentReminders,
                  onChanged: (value) =>
                      setState(() => _appointmentReminders = value),
                ),
                _buildSwitchTile(
                  title: 'Appointment Updates',
                  subtitle: 'Confirmations, cancellations, reschedules',
                  icon: Icons.calendar_today,
                  value: _appointmentUpdates,
                  onChanged: (value) =>
                      setState(() => _appointmentUpdates = value),
                ),
                _buildSwitchTile(
                  title: 'Payment Notifications',
                  subtitle: 'Payment confirmations and refunds',
                  icon: Icons.payment,
                  value: _paymentNotifications,
                  onChanged: (value) =>
                      setState(() => _paymentNotifications = value),
                ),
                _buildSwitchTile(
                  title: 'Session Notes',
                  subtitle: 'When your practitioner adds session notes',
                  icon: Icons.note,
                  value: _sessionNotes,
                  onChanged: (value) => setState(() => _sessionNotes = value),
                ),
                _buildSwitchTile(
                  title: 'Outcome Notifications',
                  subtitle: 'When outcomes are recorded',
                  icon: Icons.assessment,
                  value: _outcomeNotifications,
                  onChanged: (value) =>
                      setState(() => _outcomeNotifications = value),
                ),
                _buildSwitchTile(
                  title: 'Message Notifications',
                  subtitle: 'New messages from practitioners',
                  icon: Icons.message,
                  value: _messageNotifications,
                  onChanged: (value) =>
                      setState(() => _messageNotifications = value),
                ),
                _buildSwitchTile(
                  title: 'Promotional Emails',
                  subtitle: 'Special offers and wellness tips',
                  icon: Icons.local_offer,
                  value: _promotionalEmails,
                  onChanged: (value) =>
                      setState(() => _promotionalEmails = value),
                ),
                _buildSwitchTile(
                  title: 'System Announcements',
                  subtitle: 'Important platform updates',
                  icon: Icons.announcement,
                  value: _systemAnnouncements,
                  onChanged: (value) =>
                      setState(() => _systemAnnouncements = value),
                ),

                const SizedBox(height: 32),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Preferences'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
