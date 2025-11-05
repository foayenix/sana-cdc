import { Injectable, Logger, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface CreateConversationDto {
  clientId: string;
  practitionerId: string;
  appointmentId?: string;
}

export interface SendMessageDto {
  conversationId: string;
  senderId: string;
  text?: string;
  attachmentUrl?: string;
  attachmentType?: string;
  isSystemMessage?: boolean;
  metadata?: any;
}

export interface GetConversationsDto {
  userId: string;
  archived?: boolean;
  limit?: number;
  offset?: number;
}

export interface GetMessagesDto {
  conversationId: string;
  limit?: number;
  offset?: number;
}

@Injectable()
export class MessagesService {
  private readonly logger = new Logger(MessagesService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Get or create a conversation between client and practitioner
   */
  async getOrCreateConversation(dto: CreateConversationDto) {
    const { clientId, practitionerId, appointmentId } = dto;

    // Check if conversation already exists
    let conversation = await this.prisma.conversation.findUnique({
      where: {
        clientId_practitionerId: {
          clientId,
          practitionerId,
        },
      },
      include: {
        client: {
          select: {
            id: true,
            name: true,
            email: true,
            profilePhoto: true,
          },
        },
        practitioner: {
          select: {
            id: true,
            name: true,
            email: true,
            profilePhoto: true,
          },
        },
      },
    });

    if (!conversation) {
      // Create new conversation
      conversation = await this.prisma.conversation.create({
        data: {
          clientId,
          practitionerId,
          appointmentId,
        },
        include: {
          client: {
            select: {
              id: true,
              name: true,
              email: true,
              profilePhoto: true,
            },
          },
          practitioner: {
            select: {
              id: true,
              name: true,
              email: true,
              profilePhoto: true,
            },
          },
        },
      });

      this.logger.log(`Created new conversation: ${conversation.id}`);
    }

    return conversation;
  }

  /**
   * Get user's conversations
   */
  async getConversations(dto: GetConversationsDto) {
    const { userId, archived = false, limit = 50, offset = 0 } = dto;

    // Check if user is client or practitioner
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isClient = user.role === 'CLIENT';
    const whereClause: any = isClient
      ? { clientId: userId, clientArchived: archived }
      : { practitionerId: userId, practitionerArchived: archived };

    const conversations = await this.prisma.conversation.findMany({
      where: whereClause,
      include: {
        client: {
          select: {
            id: true,
            name: true,
            email: true,
            profilePhoto: true,
          },
        },
        practitioner: {
          select: {
            id: true,
            name: true,
            email: true,
            profilePhoto: true,
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { lastMessageAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const total = await this.prisma.conversation.count({
      where: whereClause,
    });

    return { conversations, total };
  }

  /**
   * Get messages in a conversation
   */
  async getMessages(dto: GetMessagesDto, userId: string) {
    const { conversationId, limit = 50, offset = 0 } = dto;

    // Verify user has access to this conversation
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (conversation.clientId !== userId && conversation.practitionerId !== userId) {
      throw new ForbiddenException('You do not have access to this conversation');
    }

    const messages = await this.prisma.message.findMany({
      where: { conversationId },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            profilePhoto: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const total = await this.prisma.message.count({
      where: { conversationId },
    });

    // Reverse to show oldest first
    return { messages: messages.reverse(), total };
  }

  /**
   * Send a message
   */
  async sendMessage(dto: SendMessageDto) {
    const { conversationId, senderId, text, attachmentUrl, attachmentType, isSystemMessage = false, metadata } = dto;

    // Validate message has content
    if (!text && !attachmentUrl) {
      throw new BadRequestException('Message must have text or attachment');
    }

    // Get conversation
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Verify sender has access
    if (!isSystemMessage && conversation.clientId !== senderId && conversation.practitionerId !== senderId) {
      throw new ForbiddenException('You do not have access to this conversation');
    }

    // Determine receiver
    const receiverId = conversation.clientId === senderId ? conversation.practitionerId : conversation.clientId;

    // Create message
    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderId,
        receiverId,
        text,
        attachmentUrl,
        attachmentType,
        isSystemMessage,
        metadata,
      },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            profilePhoto: true,
          },
        },
        receiver: {
          select: {
            id: true,
            name: true,
            profilePhoto: true,
          },
        },
      },
    });

    // Update conversation
    const isClient = conversation.clientId === senderId;
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessageText: text || '[Attachment]',
        lastMessageAt: new Date(),
        clientUnread: isClient ? conversation.clientUnread : conversation.clientUnread + 1,
        practitionerUnread: isClient ? conversation.practitionerUnread + 1 : conversation.practitionerUnread,
      },
    });

    this.logger.log(`Message sent in conversation ${conversationId} by ${senderId}`);

    return message;
  }

  /**
   * Mark messages as read
   */
  async markAsRead(conversationId: string, userId: string) {
    // Get conversation
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Verify user has access
    if (conversation.clientId !== userId && conversation.practitionerId !== userId) {
      throw new ForbiddenException('You do not have access to this conversation');
    }

    // Mark all unread messages as read
    await this.prisma.message.updateMany({
      where: {
        conversationId,
        receiverId: userId,
        read: false,
      },
      data: {
        read: true,
        readAt: new Date(),
      },
    });

    // Reset unread count for user
    const isClient = conversation.clientId === userId;
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: {
        clientUnread: isClient ? 0 : conversation.clientUnread,
        practitionerUnread: isClient ? conversation.practitionerUnread : 0,
      },
    });

    this.logger.log(`Messages marked as read in conversation ${conversationId} by ${userId}`);

    return { success: true };
  }

  /**
   * Archive a conversation
   */
  async archiveConversation(conversationId: string, userId: string) {
    // Get conversation
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Verify user has access
    if (conversation.clientId !== userId && conversation.practitionerId !== userId) {
      throw new ForbiddenException('You do not have access to this conversation');
    }

    // Archive for user
    const isClient = conversation.clientId === userId;
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: {
        clientArchived: isClient ? true : conversation.clientArchived,
        practitionerArchived: isClient ? conversation.practitionerArchived : true,
      },
    });

    this.logger.log(`Conversation ${conversationId} archived by ${userId}`);

    return { success: true };
  }

  /**
   * Unarchive a conversation
   */
  async unarchiveConversation(conversationId: string, userId: string) {
    // Get conversation
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    // Verify user has access
    if (conversation.clientId !== userId && conversation.practitionerId !== userId) {
      throw new ForbiddenException('You do not have access to this conversation');
    }

    // Unarchive for user
    const isClient = conversation.clientId === userId;
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: {
        clientArchived: isClient ? false : conversation.clientArchived,
        practitionerArchived: isClient ? conversation.practitionerArchived : false,
      },
    });

    this.logger.log(`Conversation ${conversationId} unarchived by ${userId}`);

    return { success: true };
  }

  /**
   * Get total unread count for user
   */
  async getUnreadCount(userId: string) {
    // Check if user is client or practitioner
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isClient = user.role === 'CLIENT';
    const conversations = await this.prisma.conversation.findMany({
      where: isClient ? { clientId: userId } : { practitionerId: userId },
      select: isClient ? { clientUnread: true } : { practitionerUnread: true },
    });

    const total = conversations.reduce((sum, conv) => {
      return sum + (isClient ? conv.clientUnread || 0 : conv.practitionerUnread || 0);
    }, 0);

    return { unreadCount: total };
  }
}
