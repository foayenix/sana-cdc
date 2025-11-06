import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/journal_service.dart';
import '../../../data/models/journal.dart';
import '../../../core/constants/app_constants.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _isLoadingMore = false;
  int? _selectedMood;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(journalEntriesProvider.notifier).loadEntries();
      ref.read(journalEntriesProvider.notifier).loadStats();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final state = ref.read(journalEntriesProvider);
    if (state.entries.length >= state.total) return;

    setState(() => _isLoadingMore = true);
    await ref.read(journalEntriesProvider.notifier).loadEntries(
          mood: _selectedMood,
          tags: _selectedTags.isEmpty ? null : _selectedTags,
          offset: state.entries.length,
        );
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(journalEntriesProvider.notifier).refresh();
              ref.read(journalEntriesProvider.notifier).loadStats();
            },
          ),
        ],
      ),
      body: state.isLoading && state.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(journalEntriesProvider.notifier).refresh();
                    ref.read(journalEntriesProvider.notifier).loadStats();
                  },
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.stats != null) _buildStatsCard(state.stats!),
                      const SizedBox(height: 16),
                      Text('Entries', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (state.entries.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No journal entries yet'),
                        ))
                      else
                        ...state.entries.map(_buildEntryCard),
                      if (_isLoadingMore)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppConstants.routeJournalEntry),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(JournalStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatItem('Total', stats.totalEntries.toString())),
                Expanded(child: _buildStatItem('This Week', stats.entriesThisWeek.toString())),
                Expanded(child: _buildStatItem('Avg Mood', stats.averageMood.toStringAsFixed(1))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: entry.mood != null
            ? Text(JournalService.getMoodEmoji(entry.mood!), style: const TextStyle(fontSize: 32))
            : null,
        title: Text(
          entry.content.length > 50 ? '${entry.content.substring(0, 50)}...' : entry.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(JournalService.formatDateTime(entry.createdAt)),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: entry.tags.take(3).map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteEntry(entry),
        ),
        onTap: () => context.push('${AppConstants.routeJournalEntry}?id=${entry.id}'),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Entries'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int?>(
              value: _selectedMood,
              decoration: const InputDecoration(labelText: 'Mood'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...List.generate(5, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${JournalService.getMoodEmoji(i + 1)} ${JournalService.getMoodLabel(i + 1)}'),
                )),
              ],
              onChanged: (value) => setState(() => _selectedMood = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMood = null;
                _selectedTags = [];
              });
              Navigator.pop(context);
              ref.read(journalEntriesProvider.notifier).loadEntries();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(journalEntriesProvider.notifier).loadEntries(
                mood: _selectedMood,
                tags: _selectedTags.isEmpty ? null : _selectedTags,
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
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

    if (confirmed == true) {
      try {
        await ref.read(journalEntriesProvider.notifier).deleteEntry(entry.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
