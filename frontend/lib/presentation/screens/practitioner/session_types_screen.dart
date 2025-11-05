import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/custom_text_field.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/data/services/session_types_service.dart';

final sessionTypesProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(sessionTypesServiceProvider);
  return await service.getMySessionTypes(includeInactive: false);
});

class SessionTypesScreen extends ConsumerWidget {
  const SessionTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionTypesAsync = ref.watch(sessionTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Types'),
      ),
      body: sessionTypesAsync.when(
        data: (sessions) => sessions.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(sessionTypesProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _buildSessionCard(context, ref, session);
                  },
                ),
              ),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(sessionTypesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSessionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Session Type'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Session Types',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create session types to offer to your clients',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, WidgetRef ref, dynamic session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          session.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(session.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${session.durationMinutes} min'),
                const SizedBox(width: 16),
                Icon(Icons.payments, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('£${session.priceGBP.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showSessionDialog(context, ref, session: session);
            } else if (value == 'delete') {
              _deleteSession(context, ref, session.id);
            }
          },
        ),
      ),
    );
  }

  void _showSessionDialog(BuildContext context, WidgetRef ref, {dynamic session}) {
    showDialog(
      context: context,
      builder: (context) => _SessionDialog(session: session),
    ).then((result) {
      if (result == true) {
        ref.invalidate(sessionTypesProvider);
      }
    });
  }

  Future<void> _deleteSession(BuildContext context, WidgetRef ref, String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session Type'),
        content: const Text('Are you sure you want to delete this session type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(sessionTypesServiceProvider);
        await service.deleteSessionType(sessionId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session type deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(sessionTypesProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _SessionDialog extends ConsumerStatefulWidget {
  final dynamic session;

  const _SessionDialog({this.session});

  @override
  ConsumerState<_SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends ConsumerState<_SessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session?.name ?? '');
    _descriptionController = TextEditingController(text: widget.session?.description ?? '');
    _durationController = TextEditingController(
      text: widget.session?.durationMinutes?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.session?.priceGBP?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(sessionTypesServiceProvider);

      if (widget.session == null) {
        await service.createSessionType(
          name: _nameController.text,
          description: _descriptionController.text,
          durationMinutes: int.parse(_durationController.text),
          priceGBP: double.parse(_priceController.text),
        );
      } else {
        await service.updateSessionType(
          widget.session.id,
          {
            'name': _nameController.text,
            'description': _descriptionController.text,
            'durationMinutes': int.parse(_durationController.text),
            'priceGBP': double.parse(_priceController.text),
          },
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.session == null
                  ? 'Session type created successfully'
                  : 'Session type updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.session == null ? 'New Session Type' : 'Edit Session Type'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Session Name',
                      hint: 'e.g., Initial Consultation',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Brief description of the session',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _durationController,
                      label: 'Duration (minutes)',
                      hint: 'e.g., 60',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter duration';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _priceController,
                      label: 'Price (GBP)',
                      hint: 'e.g., 75.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSession,
          child: Text(widget.session == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
