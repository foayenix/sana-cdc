import {
  Controller,
  Get,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  // Get user's notifications
  @Get()
  async getNotifications(
    @Request() req,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset: number,
  ) {
    const userId = req.user.userId;
    return await this.notificationsService.getUserNotifications(
      userId,
      limit,
      offset,
    );
  }

  // Get unread notification count
  @Get('unread-count')
  async getUnreadCount(@Request() req) {
    const userId = req.user.userId;
    const result = await this.notificationsService.getUserNotifications(
      userId,
      1,
      0,
    );
    return { unreadCount: result.unreadCount };
  }

  // Mark notification as read
  @Put(':id/read')
  async markAsRead(@Param('id') notificationId: string, @Request() req) {
    const userId = req.user.userId;
    return await this.notificationsService.markAsRead(notificationId, userId);
  }

  // Mark all notifications as read
  @Put('read-all')
  async markAllAsRead(@Request() req) {
    const userId = req.user.userId;
    return await this.notificationsService.markAllAsRead(userId);
  }

  // Get notification preferences
  @Get('preferences')
  async getPreferences(@Request() req) {
    const userId = req.user.userId;
    return await this.notificationsService.getPreferences(userId);
  }

  // Update notification preferences
  @Put('preferences')
  async updatePreferences(@Request() req, @Body() updates: any) {
    const userId = req.user.userId;
    return await this.notificationsService.updatePreferences(userId, updates);
  }
}
