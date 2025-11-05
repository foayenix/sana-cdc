import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  DefaultValuePipe,
  ParseBoolPipe,
  ParseIntPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AvailabilityService,
  CreateAvailabilitySlotDto,
  UpdateAvailabilitySlotDto,
  CreateTimeOffDto,
  CreateAvailabilityOverrideDto,
} from './availability.service';
import { DayOfWeek, TimeOffStatus } from '@prisma/client';

@Controller('availability')
@UseGuards(JwtAuthGuard)
export class AvailabilityController {
  constructor(private readonly availabilityService: AvailabilityService) {}

  @Post('slots')
  async createAvailabilitySlot(@Body() dto: CreateAvailabilitySlotDto, @Request() req) {
    return await this.availabilityService.createAvailabilitySlot(dto);
  }

  @Get('slots/:practitionerId')
  async getAvailabilitySlots(
    @Param('practitionerId') practitionerId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe) activeOnly?: boolean,
  ) {
    return await this.availabilityService.getAvailabilitySlots(practitionerId, activeOnly);
  }

  @Put('slots/:id')
  async updateAvailabilitySlot(
    @Param('id') id: string,
    @Body() dto: UpdateAvailabilitySlotDto,
    @Request() req,
  ) {
    const practitionerId = req.user.practitionerProfileId;
    return await this.availabilityService.updateAvailabilitySlot(id, practitionerId, dto);
  }

  @Delete('slots/:id')
  async deleteAvailabilitySlot(@Param('id') id: string, @Request() req) {
    const practitionerId = req.user.practitionerProfileId;
    return await this.availabilityService.deleteAvailabilitySlot(id, practitionerId);
  }

  @Post('slots/bulk')
  async bulkCreateAvailabilitySlots(@Body() body: { slots: CreateAvailabilitySlotDto[] }) {
    return await this.availabilityService.bulkCreateAvailabilitySlots(body.slots);
  }

  @Post('time-off')
  async createTimeOff(@Body() dto: CreateTimeOffDto, @Request() req) {
    return await this.availabilityService.createTimeOff(dto);
  }

  @Get('time-off/:practitionerId')
  async getTimeOffs(
    @Param('practitionerId') practitionerId: string,
    @Query('status') status?: TimeOffStatus,
  ) {
    return await this.availabilityService.getTimeOffs(practitionerId, status);
  }

  @Put('time-off/:id/status')
  async updateTimeOffStatus(
    @Param('id') id: string,
    @Body() body: { status: TimeOffStatus },
    @Request() req,
  ) {
    const approvedBy = req.user.userId;
    return await this.availabilityService.updateTimeOffStatus(id, body.status, approvedBy);
  }

  @Post('overrides')
  async createAvailabilityOverride(@Body() dto: CreateAvailabilityOverrideDto, @Request() req) {
    return await this.availabilityService.createAvailabilityOverride(dto);
  }

  @Get('overrides/:practitionerId')
  async getAvailabilityOverrides(
    @Param('practitionerId') practitionerId: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return await this.availabilityService.getAvailabilityOverrides(
      practitionerId,
      new Date(startDate),
      new Date(endDate),
    );
  }
}
