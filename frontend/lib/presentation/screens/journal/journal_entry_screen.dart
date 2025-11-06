import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/journal_service.dart';
import '../../../data/models/journal.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const JournalEntryScreen({super.key, this.entryId});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  int? _selectedMood;
  List<String> _tags = [];
  bool _isLoading = false;
  JournalEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      _loadEntry();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(journalServiceProvider);
      final entry = await service.getEntryById(widget.entryId!);
      setState(() {
        _existingEntry = entry;
        _contentController.text = entry.content;
        _selectedMood = entry.mood;
        _tags = List.from(entry.tags);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId != null ? 'Edit Entry' : 'New Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How are you feeling?', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) {
                              final mood = index + 1;
                              return InkWell(
                                onTap: () => setState(() => _selectedMood = mood),
                                child: Column(
                                  children: [
                                    Text(
                                      JournalService.getMoodEmoji(mood),
                                      style: TextStyle(
                                        fontSize: _selectedMood == mood ? 48 : 32,
                                      ),
                                    ),
                                    if (_selectedMood == mood)
                                      Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter some content';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _tags.map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() => _tags.remove(tag));
                              },
                            )).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a tag',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: _addTag,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addTag(_tagController.text),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.entryId != null) {
        // Update existing entry
        await ref.read(journalEntriesProvider.notifier).updateEntry(
              id: widget.entryId!,
              content: _contentController.text.trim(),
              mood: _selectedMood,
              tags: _tags,
            );
      } else {
        // Create new entry
        await ref.read(journalEntriesProvider.notifier).createEntry(
              content: _contentController.text.trim(),
              mood: _selectedMood,
              tags: _tags,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entryId != null
                ? 'Entry updated successfully'
                : 'Entry created successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
