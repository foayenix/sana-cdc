import {
  Controller,
  Get,
  Query,
  UseGuards,
  Request,
  ParseEnumPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
@UseGuards(JwtAuthGuard)
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  // Get client analytics dashboard
  @Get('client')
  async getClientAnalytics(
    @Request() req,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const userId = req.user.userId;
    const dateRange = {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
    };
    return await this.analyticsService.getClientAnalytics(userId, dateRange);
  }

  // Get practitioner analytics dashboard
  @Get('practitioner')
  async getPractitionerAnalytics(
    @Request() req,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const userId = req.user.userId;
    const dateRange = {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
    };
    return await this.analyticsService.getPractitionerAnalytics(
      userId,
      dateRange,
    );
  }
}
