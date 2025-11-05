import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/data/models/practitioner.dart';
import 'package:sana_app/data/services/practitioners_service.dart';

final availabilityProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(practitionersServiceProvider);
  return await service.getAvailability();
});

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final Map<int, List<AvailabilitySlot>> _weeklySlots = {
    0: [], // Sunday
    1: [], // Monday
    2: [], // Tuesday
    3: [], // Wednesday
    4: [], // Thursday
    5: [], // Friday
    6: [], // Saturday
  };

  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    // Load availability will happen through the provider
  }

  void _loadAvailability(List<AvailabilitySlot> slots) {
    setState(() {
      // Clear existing slots
      for (var day in _weeklySlots.keys) {
        _weeklySlots[day] = [];
      }

      // Group slots by day
      for (var slot in slots) {
        _weeklySlots[slot.dayOfWeek]?.add(slot);
      }

      // Sort slots by start time
      for (var day in _weeklySlots.keys) {
        _weeklySlots[day]?.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
    });
  }

  Future<void> _saveAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(practitionersServiceProvider);

      // Flatten all slots
      final allSlots = <AvailabilitySlot>[];
      for (var day in _weeklySlots.keys) {
        allSlots.addAll(_weeklySlots[day]!);
      }

      await service.setAvailability(allSlots);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _hasChanges = false;
        });
        ref.invalidate(availabilityProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addTimeSlot(int dayOfWeek) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _TimeSlotDialog(dayName: _dayNames[dayOfWeek]),
    );

    if (result != null) {
      final startTime = result['startTime']!;
      final endTime = result['endTime']!;

      setState(() {
        _weeklySlots[dayOfWeek]?.add(
          AvailabilitySlot(
            dayOfWeek: dayOfWeek,
            startTime: startTime,
            endTime: endTime,
          ),
        );
        _weeklySlots[dayOfWeek]?.sort((a, b) => a.startTime.compareTo(b.startTime));
        _hasChanges = true;
      });
    }
  }

  void _removeTimeSlot(int dayOfWeek, int index) {
    setState(() {
      _weeklySlots[dayOfWeek]?.removeAt(index);
      _hasChanges = true;
    });
  }

  void _copyToAllDays(int fromDay) {
    final slots = _weeklySlots[fromDay]!;
    if (slots.isEmpty) return;

    setState(() {
      for (var day in _weeklySlots.keys) {
        if (day != fromDay) {
          _weeklySlots[day] = slots
              .map((slot) => AvailabilitySlot(
                    dayOfWeek: day,
                    startTime: slot.startTime,
                    endTime: slot.endTime,
                  ))
              .toList();
        }
      }
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${_dayNames[fromDay]} schedule to all days'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(availabilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveAvailability,
              child: const Text(
                'SAVE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: availabilityAsync.when(
        data: (slots) {
          // Load slots on first build
          if (_weeklySlots.values.every((slots) => slots.isEmpty) && slots.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadAvailability(slots);
            });
          }

          return _isLoading
              ? const LoadingIndicator()
              : Column(
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Set your weekly availability. Clients will be able to book appointments during these times.',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Weekly Schedule
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          return _buildDayCard(index);
                        },
                      ),
                    ),

                    // Save Button
                    if (_hasChanges)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: CustomButton(
                          text: 'Save Availability',
                          onPressed: _saveAvailability,
                        ),
                      ),
                  ],
                );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading availability: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(availabilityProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(int dayOfWeek) {
    final slots = _weeklySlots[dayOfWeek] ?? [];
    final hasSlots = slots.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              _dayNames[dayOfWeek],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (hasSlots)
              Chip(
                label: Text('${slots.length} slot${slots.length > 1 ? 's' : ''}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time Slots
                if (hasSlots)
                  ...slots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;
                    return Card(
                      color: Colors.blue[50],
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text('${slot.startTime} - ${slot.endTime}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeTimeSlot(dayOfWeek, index),
                        ),
                      ),
                    );
                  }),

                if (!hasSlots)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No availability set for this day',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addTimeSlot(dayOfWeek),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Time Slot'),
                      ),
                    ),
                    if (hasSlots) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_all),
                        tooltip: 'Copy to all days',
                        onPressed: () => _copyToAllDays(dayOfWeek),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlotDialog extends StatefulWidget {
  final String dayName;

  const _TimeSlotDialog({required this.dayName});

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Time Slot - ${widget.dayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Start Time'),
            subtitle: Text(_formatTime(_startTime)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('End Time'),
            subtitle: Text(_formatTime(_endTime)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'startTime': _formatTime(_startTime),
              'endTime': _formatTime(_endTime),
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
