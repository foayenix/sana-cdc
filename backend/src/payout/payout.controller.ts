import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  Request,
} from '@nestjs/common';
import {
  PayoutService,
  CreatePayoutDto,
  GetPayoutsDto,
} from './payout.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { PayoutStatus } from '@prisma/client';

@Controller('payouts')
@UseGuards(JwtAuthGuard)
export class PayoutController {
  constructor(private readonly payoutService: PayoutService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles('PRACTITIONER', 'ADMIN')
  @HttpCode(HttpStatus.CREATED)
  async createPayout(@Body() dto: CreatePayoutDto) {
    const payout = await this.payoutService.createPayout(dto);
    return {
      success: true,
      message: 'Payout created successfully',
      data: payout,
    };
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles('PRACTITIONER')
  @HttpCode(HttpStatus.OK)
  async getPayouts(
    @Request() req,
    @Query('status') status?: PayoutStatus,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    // Get practitioner profile ID
    const user = await req.user;
    const practitionerProfile = await this.payoutService['prisma'].practitionerProfile.findUnique({
      where: { userId: user.userId },
      select: { id: true },
    });

    if (!practitionerProfile) {
      return {
        success: false,
        message: 'Practitioner profile not found',
      };
    }

    const dto: GetPayoutsDto = {
      practitionerId: practitionerProfile.id,
      status,
      limit: limit ? parseInt(limit, 10) : undefined,
      offset: offset ? parseInt(offset, 10) : undefined,
    };

    const result = await this.payoutService.getPayouts(dto);

    return {
      success: true,
      data: result.payouts,
      pagination: {
        total: result.total,
        limit: dto.limit || 50,
        offset: dto.offset || 0,
      },
    };
  }

  @Get('summary')
  @UseGuards(RolesGuard)
  @Roles('PRACTITIONER')
  @HttpCode(HttpStatus.OK)
  async getPayoutSummary(@Request() req) {
    // Get practitioner profile ID
    const user = await req.user;
    const practitionerProfile = await this.payoutService['prisma'].practitionerProfile.findUnique({
      where: { userId: user.userId },
      select: { id: true },
    });

    if (!practitionerProfile) {
      return {
        success: false,
        message: 'Practitioner profile not found',
      };
    }

    const summary = await this.payoutService.getPayoutSummary(
      practitionerProfile.id,
    );

    return {
      success: true,
      data: summary,
    };
  }

  @Get('unpaid-payments')
  @UseGuards(RolesGuard)
  @Roles('PRACTITIONER')
  @HttpCode(HttpStatus.OK)
  async getUnpaidPayments(
    @Request() req,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    // Get practitioner profile ID
    const user = await req.user;
    const practitionerProfile = await this.payoutService['prisma'].practitionerProfile.findUnique({
      where: { userId: user.userId },
      select: { id: true },
    });

    if (!practitionerProfile) {
      return {
        success: false,
        message: 'Practitioner profile not found',
      };
    }

    const result = await this.payoutService.getUnpaidPayments(
      practitionerProfile.id,
      limit ? parseInt(limit, 10) : undefined,
      offset ? parseInt(offset, 10) : undefined,
    );

    return {
      success: true,
      data: result.payments,
      pagination: {
        total: result.total,
        limit: limit ? parseInt(limit, 10) : 50,
        offset: offset ? parseInt(offset, 10) : 0,
      },
    };
  }

  @Get('statistics')
  @UseGuards(RolesGuard)
  @Roles('PRACTITIONER')
  @HttpCode(HttpStatus.OK)
  async getPayoutStatistics(
    @Request() req,
    @Query('period') period?: 'week' | 'month' | 'year',
  ) {
    // Get practitioner profile ID
    const user = await req.user;
    const practitionerProfile = await this.payoutService['prisma'].practitionerProfile.findUnique({
      where: { userId: user.userId },
      select: { id: true },
    });

    if (!practitionerProfile) {
      return {
        success: false,
        message: 'Practitioner profile not found',
      };
    }

    const statistics = await this.payoutService.getPayoutStatistics(
      practitionerProfile.id,
      period,
    );

    return {
      success: true,
      data: statistics,
    };
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles('PRACTITIONER', 'ADMIN')
  @HttpCode(HttpStatus.OK)
  async getPayoutById(@Param('id') id: string) {
    const payout = await this.payoutService.getPayoutById(id);
    return {
      success: true,
      data: payout,
    };
  }

  @Put(':id/status')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @HttpCode(HttpStatus.OK)
  async updatePayoutStatus(
    @Param('id') id: string,
    @Body('status') status: PayoutStatus,
    @Body('stripePayoutId') stripePayoutId?: string,
    @Body('failureReason') failureReason?: string,
  ) {
    const payout = await this.payoutService.updatePayoutStatus(
      id,
      status,
      stripePayoutId,
      failureReason,
    );

    return {
      success: true,
      message: 'Payout status updated successfully',
      data: payout,
    };
  }

  @Put(':id/schedule')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @HttpCode(HttpStatus.OK)
  async schedulePayout(
    @Param('id') id: string,
    @Body('scheduledFor') scheduledFor: Date,
  ) {
    const payout = await this.payoutService.schedulePayout(id, scheduledFor);

    return {
      success: true,
      message: 'Payout scheduled successfully',
      data: payout,
    };
  }
}
