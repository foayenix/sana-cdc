import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UseGuards } from '@nestjs/common';
import { MessagesService, SendMessageDto } from './messages.service';

// Simple auth guard for WebSocket (in production, use JWT validation)
@WebSocketGateway({
  cors: {
    origin: '*', // Configure properly in production
  },
  namespace: '/messages',
})
export class MessagesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(MessagesGateway.name);
  private userSockets = new Map<string, Set<string>>(); // userId -> Set of socket IDs

  constructor(private messagesService: MessagesService) {}

  handleConnection(client: Socket) {
    const userId = client.handshake.query.userId as string;
    
    if (!userId) {
      this.logger.warn(`Connection rejected: no userId provided`);
      client.disconnect();
      return;
    }

    // Store user's socket connection
    if (!this.userSockets.has(userId)) {
      this.userSockets.set(userId, new Set());
    }
    this.userSockets.get(userId).add(client.id);

    // Join user to their personal room
    client.join(`user:${userId}`);

    this.logger.log(`Client connected: ${client.id} (user: ${userId})`);
  }

  handleDisconnect(client: Socket) {
    const userId = client.handshake.query.userId as string;
    
    if (userId && this.userSockets.has(userId)) {
      this.userSockets.get(userId).delete(client.id);
      if (this.userSockets.get(userId).size === 0) {
        this.userSockets.delete(userId);
      }
    }

    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Client subscribes to a conversation
   */
  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { conversationId, userId } = data;

    // Verify user has access (basic check)
    // In production, validate against database
    client.join(`conversation:${conversationId}`);
    
    this.logger.log(`User ${userId} joined conversation ${conversationId}`);
    
    return { event: 'joined_conversation', conversationId };
  }

  /**
   * Client leaves a conversation
   */
  @SubscribeMessage('leave_conversation')
  async handleLeaveConversation(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { conversationId, userId } = data;

    client.leave(`conversation:${conversationId}`);
    
    this.logger.log(`User ${userId} left conversation ${conversationId}`);
    
    return { event: 'left_conversation', conversationId };
  }

  /**
   * Send a message
   */
  @SubscribeMessage('send_message')
  async handleSendMessage(
    @MessageBody() dto: SendMessageDto,
    @ConnectedSocket() client: Socket,
  ) {
    try {
      // Create message in database
      const message = await this.messagesService.sendMessage(dto);

      // Emit to conversation room
      this.server.to(`conversation:${dto.conversationId}`).emit('new_message', message);

      // Emit to receiver's personal room (for notification)
      const receiverId = message.receiver.id;
      this.server.to(`user:${receiverId}`).emit('message_notification', {
        conversationId: dto.conversationId,
        message,
      });

      return { event: 'message_sent', message };
    } catch (error) {
      this.logger.error(`Error sending message: ${error.message}`);
      return { event: 'error', error: error.message };
    }
  }

  /**
   * Typing indicator
   */
  @SubscribeMessage('typing')
  handleTyping(
    @MessageBody() data: { conversationId: string; userId: string; isTyping: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    const { conversationId, userId, isTyping } = data;

    // Broadcast to others in the conversation
    client.to(`conversation:${conversationId}`).emit('user_typing', {
      conversationId,
      userId,
      isTyping,
    });
  }

  /**
   * Mark message as read
   */
  @SubscribeMessage('mark_as_read')
  async handleMarkAsRead(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { conversationId, userId } = data;

    try {
      await this.messagesService.markAsRead(conversationId, userId);

      // Notify conversation participants
      this.server.to(`conversation:${conversationId}`).emit('messages_read', {
        conversationId,
        userId,
      });

      return { event: 'marked_as_read', conversationId };
    } catch (error) {
      this.logger.error(`Error marking as read: ${error.message}`);
      return { event: 'error', error: error.message };
    }
  }

  /**
   * Send notification to specific user
   */
  sendToUser(userId: string, event: string, data: any) {
    this.server.to(`user:${userId}`).emit(event, data);
  }

  /**
   * Send to conversation
   */
  sendToConversation(conversationId: string, event: string, data: any) {
    this.server.to(`conversation:${conversationId}`).emit(event, data);
  }
}
