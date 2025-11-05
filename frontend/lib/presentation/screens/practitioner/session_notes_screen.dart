import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/models/appointment.dart';
import 'package:sana_app/data/models/session_note.dart';
import 'package:sana_app/data/services/appointments_service.dart';
import 'package:sana_app/data/services/session_notes_service.dart';

// Provider for completed appointments (for creating notes)
final completedAppointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>(
  (ref) async {
    final service = ref.watch(appointmentsServiceProvider);
    final appointments = await service.getAppointments(
      status: AppointmentStatus.completed,
    );
    return appointments;
  },
);

// Provider for session notes
final sessionNotesProvider = FutureProvider.autoDispose<List<SessionNote>>(
  (ref) async {
    final service = ref.watch(sessionNotesServiceProvider);
    return await service.getSessionNotes();
  },
);

class SessionNotesScreen extends ConsumerWidget {
  const SessionNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(sessionNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Notes'),
        elevation: 0,
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sessionNotesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return _buildNoteCard(context, notes[index]);
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(sessionNotesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateNoteDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No session notes yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create notes after completing appointments',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, SessionNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showNoteDetail(context, note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_note,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Note',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          DateFormat('MMMM d, y • HH:mm').format(note.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (note.followUpRequired)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notification_important,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Follow-up',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.notes,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.recommendations != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note.recommendations!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateNoteDialog(BuildContext context, WidgetRef ref) async {
    final completedAsync = ref.read(completedAppointmentsProvider);

    await completedAsync.when(
      data: (appointments) async {
        if (appointments.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No completed appointments to create notes for'),
            ),
          );
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateSessionNoteScreen(appointments: appointments),
          ),
        );

        ref.invalidate(sessionNotesProvider);
      },
      loading: () {},
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _showNoteDetail(BuildContext context, SessionNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session Note Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Date',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d, y • HH:mm').format(note.createdAt),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Session Notes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(note.notes, style: const TextStyle(fontSize: 16)),
              if (note.privateNotes != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock, size: 16, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          Text(
                            'Private Notes (Not visible to client)',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(note.privateNotes!,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
              if (note.recommendations != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Recommendations',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(note.recommendations!,
                    style: const TextStyle(fontSize: 16)),
              ],
              if (note.followUpRequired) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Follow-up Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            if (note.followUpDate != null)
                              Text(
                                DateFormat('MMMM d, y')
                                    .format(note.followUpDate!),
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Create Session Note Screen
class CreateSessionNoteScreen extends ConsumerStatefulWidget {
  final List<Appointment> appointments;

  const CreateSessionNoteScreen({super.key, required this.appointments});

  @override
  ConsumerState<CreateSessionNoteScreen> createState() =>
      _CreateSessionNoteScreenState();
}

class _CreateSessionNoteScreenState
    extends ConsumerState<CreateSessionNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  Appointment? selectedAppointment;
  final notesController = TextEditingController();
  final privateNotesController = TextEditingController();
  final recommendationsController = TextEditingController();
  bool followUpRequired = false;
  DateTime? followUpDate;
  bool isSaving = false;

  @override
  void dispose() {
    notesController.dispose();
    privateNotesController.dispose();
    recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate() || selectedAppointment == null) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final service = ref.read(sessionNotesServiceProvider);
      await service.createSessionNote(
        appointmentId: selectedAppointment!.id,
        notes: notesController.text.trim(),
        privateNotes: privateNotesController.text.trim().isNotEmpty
            ? privateNotesController.text.trim()
            : null,
        recommendations: recommendationsController.text.trim().isNotEmpty
            ? recommendationsController.text.trim()
            : null,
        followUpRequired: followUpRequired,
        followUpDate: followUpDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session note created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Session Note'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Select Appointment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Appointment>(
              value: selectedAppointment,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose an appointment',
              ),
              items: widget.appointments.map((apt) {
                return DropdownMenuItem(
                  value: apt,
                  child: Text(
                    '${apt.client?.user.name ?? "Client"} - ${DateFormat("MMM d, y").format(apt.appointmentDate)}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedAppointment = value);
              },
              validator: (value) =>
                  value == null ? 'Please select an appointment' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Session Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter session notes (visible to client)...',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter session notes'
                      : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Private Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Not visible to client',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: privateNotesController,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter private notes...',
                prefixIcon: Icon(Icons.lock, color: Colors.amber[700]),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: recommendationsController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter recommendations for client...',
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Follow-up Required'),
              value: followUpRequired,
              onChanged: (value) {
                setState(() => followUpRequired = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (followUpRequired) ...[
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Follow-up Date'),
                subtitle: Text(
                  followUpDate != null
                      ? DateFormat('MMMM d, y').format(followUpDate!)
                      : 'Select date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => followUpDate = date);
                  }
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 32),
            CustomButton(
              text: isSaving ? 'Saving...' : 'Save Session Note',
              onPressed: isSaving ? null : _saveNote,
              isLoading: isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
