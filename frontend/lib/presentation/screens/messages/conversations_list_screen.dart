import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/message.dart';
import '../../../data/services/messages_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

/// Conversations list screen showing all user's conversations
class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    // Load conversations on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  void _loadConversations() {
    ref
        .read(conversationsNotifierProvider.notifier)
        .loadConversations(archived: _showArchived);
  }

  Future<void> _onRefresh() async {
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsNotifierProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // Unread count badge
          if (conversationsState.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    conversationsState.unreadCount > 99
                        ? '99+'
                        : conversationsState.unreadCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          // Archive toggle
          IconButton(
            icon: Icon(_showArchived ? Icons.unarchive : Icons.archive),
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
              _loadConversations();
            },
            tooltip: _showArchived ? 'Show Active' : 'Show Archived',
          ),
        ],
      ),
      body: _buildBody(conversationsState, currentUserId),
    );
  }

  Widget _buildBody(ConversationsState state, String? currentUserId) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadConversations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _showArchived ? 'No archived conversations' : 'No conversations yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _showArchived
                  ? 'Archived conversations will appear here'
                  : 'Start a conversation with a practitioner',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        itemCount: state.conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = state.conversations[index];
          return _buildConversationTile(conversation, currentUserId);
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation, String? currentUserId) {
    final isClient = currentUserId == conversation.clientId;
    final otherUser = isClient ? conversation.practitioner : conversation.client;
    final unreadCount = isClient
        ? conversation.clientUnread
        : conversation.practitionerUnread;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Archive Conversation'),
            content: const Text('Archive this conversation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Archive'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref
            .read(conversationsNotifierProvider.notifier)
            .archiveConversation(conversation.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation archived')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: otherUser?.profilePhoto != null
              ? NetworkImage(otherUser!.profilePhoto!)
              : null,
          child: otherUser?.profilePhoto == null
              ? Text(otherUser?.name[0].toUpperCase() ?? '?')
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUser?.name ?? 'Unknown User',
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (conversation.lastMessageAt != null)
              Text(
                MessagesService.formatLastMessageTime(conversation.lastMessageAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessageText ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to chat screen
          context.push(
            '${AppConstants.routeMessages}/${conversation.id}',
            extra: {
              'conversation': conversation,
              'otherUser': otherUser,
            },
          );
        },
      ),
    );
  }
}
