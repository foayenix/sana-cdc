import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  DefaultValuePipe,
  ParseIntPipe,
  ParseBoolPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MessagesService, CreateConversationDto, SendMessageDto } from './messages.service';

@Controller('messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  /**
   * Get or create a conversation
   * POST /api/messages/conversations
   */
  @Post('conversations')
  async createConversation(@Body() dto: CreateConversationDto, @Request() req) {
    return await this.messagesService.getOrCreateConversation(dto);
  }

  /**
   * Get user's conversations
   * GET /api/messages/conversations?archived=false&limit=50&offset=0
   */
  @Get('conversations')
  async getConversations(
    @Request() req,
    @Query('archived', new DefaultValuePipe(false), ParseBoolPipe) archived?: boolean,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit?: number,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset?: number,
  ) {
    const userId = req.user.userId;
    return await this.messagesService.getConversations({
      userId,
      archived,
      limit,
      offset,
    });
  }

  /**
   * Get conversation by ID
   * GET /api/messages/conversations/:id
   */
  @Get('conversations/:id')
  async getConversation(@Param('id') id: string, @Request() req) {
    const userId = req.user.userId;
    const { messages } = await this.messagesService.getMessages({ conversationId: id }, userId);
    return { id, messages };
  }

  /**
   * Get messages in a conversation
   * GET /api/messages/conversations/:id/messages?limit=50&offset=0
   */
  @Get('conversations/:id/messages')
  async getMessages(
    @Param('id') conversationId: string,
    @Request() req,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit?: number,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset?: number,
  ) {
    const userId = req.user.userId;
    return await this.messagesService.getMessages({ conversationId, limit, offset }, userId);
  }

  /**
   * Send a message
   * POST /api/messages
   */
  @Post()
  async sendMessage(@Body() dto: SendMessageDto, @Request() req) {
    return await this.messagesService.sendMessage(dto);
  }

  /**
   * Mark conversation as read
   * PUT /api/messages/conversations/:id/read
   */
  @Put('conversations/:id/read')
  async markAsRead(@Param('id') conversationId: string, @Request() req) {
    const userId = req.user.userId;
    return await this.messagesService.markAsRead(conversationId, userId);
  }

  /**
   * Archive conversation
   * PUT /api/messages/conversations/:id/archive
   */
  @Put('conversations/:id/archive')
  async archiveConversation(@Param('id') conversationId: string, @Request() req) {
    const userId = req.user.userId;
    return await this.messagesService.archiveConversation(conversationId, userId);
  }

  /**
   * Unarchive conversation
   * PUT /api/messages/conversations/:id/unarchive
   */
  @Put('conversations/:id/unarchive')
  async unarchiveConversation(@Param('id') conversationId: string, @Request() req) {
    const userId = req.user.userId;
    return await this.messagesService.unarchiveConversation(conversationId, userId);
  }

  /**
   * Get unread count
   * GET /api/messages/unread-count
   */
  @Get('unread-count')
  async getUnreadCount(@Request() req) {
    const userId = req.user.userId;
    return await this.messagesService.getUnreadCount(userId);
  }
}
