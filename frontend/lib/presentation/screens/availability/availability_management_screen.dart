import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/availability.dart';
import '../../../data/services/availability_service.dart';
import '../../providers/auth_provider.dart';

class AvailabilityManagementScreen extends ConsumerStatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  ConsumerState<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends ConsumerState<AvailabilityManagementScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final practitionerId = authState.user?.practitionerProfile?.id;
      if (practitionerId != null) {
        ref.read(availabilityNotifierProvider(practitionerId).notifier).loadAvailability();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final practitionerId = authState.user?.practitionerProfile?.id;

    if (practitionerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Availability Management')),
        body: const Center(child: Text('Practitioner profile not found')),
      );
    }

    final availabilityState = ref.watch(availabilityNotifierProvider(practitionerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Management'),
        bottom: TabBar(
          controller: TabController(length: 3, vsync: Navigator.of(context)),
          onTap: (index) => setState(() => _selectedTabIndex = index),
          tabs: const [
            Tab(text: 'Weekly Schedule'),
            Tab(text: 'Time Off'),
            Tab(text: 'Overrides'),
          ],
        ),
      ),
      body: availabilityState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildWeeklyScheduleTab(availabilityState, practitionerId),
                _buildTimeOffTab(availabilityState, practitionerId),
                _buildOverridesTab(availabilityState, practitionerId),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(practitionerId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeeklyScheduleTab(AvailabilityState state, String practitionerId) {
    if (state.slots.isEmpty) {
      return const Center(child: Text('No availability slots. Tap + to add.'));
    }

    final groupedSlots = <DayOfWeek, List<AvailabilitySlot>>{};
    for (final slot in state.slots) {
      groupedSlots.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    return ListView(
      children: DayOfWeek.values.map((day) {
        final daySlots = groupedSlots[day] ?? [];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(day.displayName),
            subtitle: Text(daySlots.isEmpty ? 'No slots' : daySlots.length.toString() + ' slots'),
            children: daySlots.map((slot) {
              return ListTile(
                title: Text(AvailabilityService.formatTime(slot.startTime) + ' - ' + AvailabilityService.formatTime(slot.endTime)),
                subtitle: slot.label != null ? Text(slot.label!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!slot.isActive) const Chip(label: Text('Inactive')),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteSlot(practitionerId, slot.id),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeOffTab(AvailabilityState state, String practitionerId) {
    if (state.timeOffs.isEmpty) {
      return const Center(child: Text('No time off requests.'));
    }

    return ListView.builder(
      itemCount: state.timeOffs.length,
      itemBuilder: (context, index) {
        final timeOff = state.timeOffs[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(timeOff.startDate.toString().substring(0, 10) + ' to ' + timeOff.endDate.toString().substring(0, 10)),
            subtitle: timeOff.reason != null ? Text(timeOff.reason!) : null,
            trailing: Chip(
              label: Text(timeOff.status.displayName),
              backgroundColor: timeOff.status == TimeOffStatus.approved ? Colors.green.shade100 : 
                timeOff.status == TimeOffStatus.rejected ? Colors.red.shade100 : Colors.orange.shade100,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverridesTab(AvailabilityState state, String practitionerId) {
    if (state.overrides.isEmpty) {
      return const Center(child: Text('No date overrides.'));
    }

    return ListView.builder(
      itemCount: state.overrides.length,
      itemBuilder: (context, index) {
        final override = state.overrides[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(override.date.toString().substring(0, 10)),
            subtitle: override.isAvailable
                ? Text(AvailabilityService.formatTime(override.startTime ?? '00:00') + ' - ' + AvailabilityService.formatTime(override.endTime ?? '23:59'))
                : const Text('Day blocked'),
            trailing: Icon(
              override.isAvailable ? Icons.check_circle : Icons.cancel,
              color: override.isAvailable ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(String practitionerId) {
    if (_selectedTabIndex == 0) {
      _showAddSlotDialog(practitionerId);
    } else if (_selectedTabIndex == 1) {
      _showAddTimeOffDialog(practitionerId);
    } else {
      _showAddOverrideDialog(practitionerId);
    }
  }

  void _showAddSlotDialog(String practitionerId) {
    DayOfWeek selectedDay = DayOfWeek.monday;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Availability Slot'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DayOfWeek>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'Day of Week'),
                items: DayOfWeek.values.map((day) => DropdownMenuItem(value: day, child: Text(day.displayName))).toList(),
                onChanged: (day) => setState(() => selectedDay = day!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(startTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: startTime);
                  if (time != null) setState(() => startTime = time);
                },
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(endTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: endTime);
                  if (time != null) setState(() => endTime = time);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final request = CreateAvailabilitySlotRequest(
                practitionerId: practitionerId,
                dayOfWeek: selectedDay,
                startTime: startTime.hour.toString().padLeft(2, '0') + ':' + startTime.minute.toString().padLeft(2, '0'),
                endTime: endTime.hour.toString().padLeft(2, '0') + ':' + endTime.minute.toString().padLeft(2, '0'),
              );
              ref.read(availabilityNotifierProvider(practitionerId).notifier).addSlot(request);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTimeOffDialog(String practitionerId) {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Time Off'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Date'),
                trailing: Text(startDate.toString().substring(0, 10)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) setState(() => startDate = date);
                },
              ),
              ListTile(
                title: const Text('End Date'),
                trailing: Text(endDate.toString().substring(0, 10)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) setState(() => endDate = date);
                },
              ),
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final request = CreateTimeOffRequest(
                practitionerId: practitionerId,
                startDate: startDate,
                endDate: endDate,
                reason: reasonController.text.isEmpty ? null : reasonController.text,
              );
              ref.read(availabilityNotifierProvider(practitionerId).notifier).requestTimeOff(request);
              Navigator.pop(context);
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showAddOverrideDialog(String practitionerId) {
    DateTime date = DateTime.now();
    bool isAvailable = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Date Override'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                trailing: Text(date.toString().substring(0, 10)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => date = d);
                },
              ),
              SwitchListTile(
                title: const Text('Available'),
                value: isAvailable,
                onChanged: (value) => setState(() => isAvailable = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final request = CreateAvailabilityOverrideRequest(
                practitionerId: practitionerId,
                date: date,
                isAvailable: isAvailable,
              );
              ref.read(availabilityNotifierProvider(practitionerId).notifier).createOverride(request);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteSlot(String practitionerId, String slotId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: const Text('Are you sure you want to delete this availability slot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(availabilityNotifierProvider(practitionerId).notifier).deleteSlot(slotId);
    }
  }
}
