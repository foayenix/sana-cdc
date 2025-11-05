import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';
import 'api_service.dart';
import '../../core/config/app_config.dart';

/// Provider for MessagesService
final messagesServiceProvider = Provider<MessagesService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MessagesService(apiService);
});

/// Service for messaging with REST API and WebSocket support
class MessagesService {
  final ApiService _apiService;
  // IO.Socket? _socket;
  // String? _currentUserId;

  MessagesService(this._apiService);

  /// Initialize WebSocket connection
  /// Uncomment when socket_io_client package is installed
  /*
  Future<void> connect(String userId) async {
    _currentUserId = userId;
    
    // Get auth token
    final token = await AppConfig.getAccessToken();
    
    // Create socket connection
    _socket = IO.io(
      '${AppConfig.apiBaseUrl}/messages',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'userId': userId})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket?.connect();

    _socket?.on('connect', (_) {
      print('WebSocket connected');
    });

    _socket?.on('disconnect', (_) {
      print('WebSocket disconnected');
    });

    _socket?.on('error', (error) {
      print('WebSocket error: $error');
    });
  }

  /// Disconnect WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
  }

  /// Join a conversation room
  void joinConversation(String conversationId) {
    if (_socket == null || _currentUserId == null) return;
    
    _socket?.emit('join_conversation', {
      'conversationId': conversationId,
      'userId': _currentUserId,
    });
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    if (_socket == null || _currentUserId == null) return;
    
    _socket?.emit('leave_conversation', {
      'conversationId': conversationId,
      'userId': _currentUserId,
    });
  }

  /// Send typing indicator
  void sendTypingStatus(String conversationId, bool isTyping) {
    if (_socket == null || _currentUserId == null) return;
    
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'userId': _currentUserId,
      'isTyping': isTyping,
    });
  }

  /// Listen for new messages
  void onNewMessage(Function(Message) callback) {
    _socket?.on('new_message', (data) {
      final message = Message.fromJson(data);
      callback(message);
    });
  }

  /// Listen for typing status
  void onUserTyping(Function(TypingStatus) callback) {
    _socket?.on('user_typing', (data) {
      final status = TypingStatus.fromJson(data);
      callback(status);
    });
  }

  /// Listen for read receipts
  void onMessagesRead(Function(Map<String, dynamic>) callback) {
    _socket?.on('messages_read', (data) {
      callback(data);
    });
  }

  /// Listen for message notifications (when not in conversation)
  void onMessageNotification(Function(Map<String, dynamic>) callback) {
    _socket?.on('message_notification', (data) {
      callback(data);
    });
  }
  */

  /// Create or get a conversation
  Future<Conversation> createConversation(CreateConversationRequest request) async {
    try {
      final response = await _apiService.dio.post(
        '/messages/conversations',
        data: request.toJson(),
      );
      return Conversation.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to create conversation',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Get user's conversations
  Future<ConversationsResponse> getConversations({
    bool archived = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/messages/conversations',
        queryParameters: {
          'archived': archived,
          'limit': limit,
          'offset': offset,
        },
      );
      return ConversationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load conversations',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Get messages in a conversation
  Future<MessagesResponse> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/messages/conversations/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return MessagesResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load messages',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Send a message (REST API)
  Future<Message> sendMessage(SendMessageRequest request) async {
    try {
      final response = await _apiService.dio.post(
        '/messages',
        data: request.toJson(),
      );
      return Message.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to send message',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Send a message via WebSocket (when available)
  /// Uncomment when socket_io_client package is installed
  /*
  void sendMessageViaWebSocket(SendMessageRequest request) {
    if (_socket == null) return;
    
    _socket?.emit('send_message', request.toJson());
  }
  */

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiService.dio.put('/messages/conversations/$conversationId/read');
      
      // Also emit via WebSocket if connected
      /*
      if (_socket != null && _currentUserId != null) {
        _socket?.emit('mark_as_read', {
          'conversationId': conversationId,
          'userId': _currentUserId,
        });
      }
      */
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to mark as read',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Archive a conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await _apiService.dio.put('/messages/conversations/$conversationId/archive');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to archive conversation',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Unarchive a conversation
  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await _apiService.dio.put('/messages/conversations/$conversationId/unarchive');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to unarchive conversation',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Get total unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.dio.get('/messages/unread-count');
      final data = UnreadCountResponse.fromJson(response.data);
      return data.unreadCount;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to get unread count',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Format timestamp for conversation list
  static String formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Format time for message bubble
  static String formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// State for conversations list
class ConversationsState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  ConversationsState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// State notifier for conversations
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final MessagesService _messagesService;

  ConversationsNotifier(this._messagesService) : super(ConversationsState());

  /// Load conversations
  Future<void> loadConversations({bool archived = false}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _messagesService.getConversations(archived: archived);
      final unreadCount = await _messagesService.getUnreadCount();

      state = state.copyWith(
        conversations: response.conversations,
        isLoading: false,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Archive a conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await _messagesService.archiveConversation(conversationId);
      
      // Remove from list
      final updatedConversations = state.conversations
          .where((c) => c.id != conversationId)
          .toList();
      
      state = state.copyWith(conversations: updatedConversations);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _messagesService.markAsRead(conversationId);
      
      // Update conversation in list
      final updatedConversations = state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(
            clientUnread: 0,
            practitionerUnread: 0,
          );
        }
        return c;
      }).toList();
      
      // Update unread count
      final unreadCount = await _messagesService.getUnreadCount();
      
      state = state.copyWith(
        conversations: updatedConversations,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for conversations state
final conversationsNotifierProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final messagesService = ref.watch(messagesServiceProvider);
  return ConversationsNotifier(messagesService);
});

/// State for chat screen
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? typingUserId;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.typingUserId,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? typingUserId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      typingUserId: typingUserId,
    );
  }
}

/// State notifier for chat
class ChatNotifier extends StateNotifier<ChatState> {
  final MessagesService _messagesService;
  final String conversationId;

  ChatNotifier(this._messagesService, this.conversationId) : super(ChatState());

  /// Load messages
  Future<void> loadMessages() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _messagesService.getMessages(conversationId);

      state = state.copyWith(
        messages: response.messages,
        isLoading: false,
      );

      // Mark as read
      await _messagesService.markAsRead(conversationId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore) return;

    try {
      state = state.copyWith(isLoadingMore: true, error: null);

      final response = await _messagesService.getMessages(
        conversationId,
        offset: state.messages.length,
      );

      // Prepend older messages
      final updatedMessages = [...response.messages, ...state.messages];

      state = state.copyWith(
        messages: updatedMessages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Send a message
  Future<void> sendMessage(String text, String senderId) async {
    try {
      final request = SendMessageRequest(
        conversationId: conversationId,
        senderId: senderId,
        text: text,
      );

      final message = await _messagesService.sendMessage(request);

      // Add message to list
      final updatedMessages = [...state.messages, message];
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add a new message (from WebSocket)
  void addMessage(Message message) {
    final updatedMessages = [...state.messages, message];
    state = state.copyWith(messages: updatedMessages);
  }

  /// Set typing status
  void setTypingUser(String? userId) {
    state = state.copyWith(typingUserId: userId);
  }
}

/// Provider for chat state (requires conversationId parameter)
final chatNotifierProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, conversationId) {
    final messagesService = ref.watch(messagesServiceProvider);
    return ChatNotifier(messagesService, conversationId);
  },
);
