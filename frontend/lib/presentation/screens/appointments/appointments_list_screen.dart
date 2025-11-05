import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/models/appointment.dart';
import 'package:sana_app/data/services/appointments_service.dart';

// Provider for fetching appointments
final appointmentsProvider = FutureProvider.autoDispose<List<Appointment>>(
  (ref) async {
    final service = ref.watch(appointmentsServiceProvider);
    return await service.getAppointments();
  },
);

class AppointmentsListScreen extends ConsumerStatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  ConsumerState<AppointmentsListScreen> createState() =>
      _AppointmentsListScreenState();
}

class _AppointmentsListScreenState
    extends ConsumerState<AppointmentsListScreen> {
  AppointmentStatus? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          // Filter appointments based on selected status
          final filteredAppointments = selectedStatus == null
              ? appointments
              : appointments
                  .where((apt) => apt.status == selectedStatus)
                  .toList();

          // Sort by date (upcoming first)
          filteredAppointments.sort(
            (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
          );

          // Separate upcoming and past appointments
          final now = DateTime.now();
          final upcomingAppointments = filteredAppointments
              .where((apt) => apt.appointmentDate.isAfter(now))
              .toList();
          final pastAppointments = filteredAppointments
              .where((apt) => apt.appointmentDate.isBefore(now))
              .toList();

          if (filteredAppointments.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(appointmentsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (selectedStatus != null) _buildFilterChip(),
                if (upcomingAppointments.isNotEmpty) ...[
                  _buildSectionHeader('Upcoming'),
                  ...upcomingAppointments
                      .map((apt) => _buildAppointmentCard(apt)),
                  const SizedBox(height: 24),
                ],
                if (pastAppointments.isNotEmpty) ...[
                  _buildSectionHeader('Past'),
                  ...pastAppointments.map((apt) => _buildAppointmentCard(apt)),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(appointmentsProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            selectedStatus == null
                ? 'No appointments yet'
                : 'No ${_getStatusText(selectedStatus!)} appointments',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first session with a practitioner',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/practitioners/search'),
            icon: const Icon(Icons.search),
            label: const Text('Find Practitioners'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Chip(
        label: Text('Filter: ${_getStatusText(selectedStatus!)}'),
        onDeleted: () {
          setState(() => selectedStatus = null);
        },
        deleteIcon: const Icon(Icons.close, size: 18),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isUpcoming = appointment.appointmentDate.isAfter(DateTime.now());
    final statusColor = _getStatusColor(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/appointments/${appointment.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.practitioner?.user.name ?? 'Practitioner',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          appointment.sessionType?.name ?? 'Session',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, y')
                        .format(appointment.appointmentDate),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm').format(appointment.appointmentDate),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${appointment.sessionType?.durationMinutes ?? 0} minutes',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              if (appointment.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  appointment.notes!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (isUpcoming &&
                  appointment.status == AppointmentStatus.scheduled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _cancelAppointment(context, appointment),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context
                            .push('/appointments/${appointment.id}/payment'),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<AppointmentStatus?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              onTap: () => Navigator.pop(context, null),
            ),
            ...AppointmentStatus.values.map(
              (status) => ListTile(
                title: Text(_getStatusText(status)),
                onTap: () => Navigator.pop(context, status),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null || result == null) {
      setState(() => selectedStatus = result);
    }
  }

  Future<void> _cancelAppointment(
      BuildContext context, Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment? '
          'Cancellations within 24 hours may not be eligible for refund.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(appointmentsServiceProvider);
        await service.cancelAppointment(appointmentId: appointment.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(appointmentsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
