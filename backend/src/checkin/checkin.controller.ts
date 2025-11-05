import { Controller, Post, Get, Body, Query, UseGuards } from '@nestjs/common';
import { CheckinService } from './checkin.service';
import { CreateCheckinDto } from './dto/create-checkin.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('checkin')
@UseGuards(JwtAuthGuard)
export class CheckinController {
  constructor(private readonly checkinService: CheckinService) {}

  /**
   * POST /api/checkin
   * Submit daily check-in
   */
  @Post()
  async submitCheckin(@CurrentUser() user: any, @Body() checkinDto: CreateCheckinDto) {
    return this.checkinService.submitCheckin(user.id, user.role, checkinDto);
  }

  /**
   * GET /api/checkin/history
   * Get check-in history
   */
  @Get('history')
  async getHistory(@CurrentUser() user: any, @Query('days') days?: string) {
    const dayCount = days ? parseInt(days, 10) : 30;
    return this.checkinService.getCheckinHistory(user.id, user.role, dayCount);
  }

  /**
   * GET /api/checkin/completion-rate
   * Get check-in completion rate
   */
  @Get('completion-rate')
  async getCompletionRate(@CurrentUser() user: any, @Query('days') days?: string) {
    const dayCount = days ? parseInt(days, 10) : 30;
    return this.checkinService.getCompletionRate(user.id, user.role, dayCount);
  }
}
