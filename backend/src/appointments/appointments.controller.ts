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
} from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole, AppointmentStatus } from '@prisma/client';

@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  // Create appointment (client books with practitioner)
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLIENT)
  async createAppointment(
    @Request() req,
    @Body()
    createDto: {
      practitionerId: string;
      sessionTypeId: string;
      appointmentDate: string;
      notes?: string;
    },
  ) {
    return this.appointmentsService.createAppointment(req.user.userId, {
      ...createDto,
      appointmentDate: new Date(createDto.appointmentDate),
    });
  }

  // Get all appointments for authenticated user
  @Get()
  @UseGuards(JwtAuthGuard)
  async getAppointments(
    @Request() req,
    @Query('status') status?: AppointmentStatus,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    const filters: any = {};
    if (status) filters.status = status;
    if (fromDate) filters.fromDate = new Date(fromDate);
    if (toDate) filters.toDate = new Date(toDate);

    return this.appointmentsService.getAppointments(
      req.user.userId,
      req.user.role,
      filters,
    );
  }

  // Get single appointment by ID
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getAppointmentById(@Request() req, @Param('id') appointmentId: string) {
    return this.appointmentsService.getAppointmentById(
      appointmentId,
      req.user.userId,
    );
  }

  // Get available time slots for a practitioner on a specific date
  @Get('slots/:practitionerId')
  async getAvailableSlots(
    @Param('practitionerId') practitionerId: string,
    @Query('date') dateString: string,
  ) {
    if (!dateString) {
      throw new Error('Date query parameter is required');
    }
    const date = new Date(dateString);
    return this.appointmentsService.getAvailableSlots(practitionerId, date);
  }

  // Update appointment (reschedule or change status)
  @Put(':id')
  @UseGuards(JwtAuthGuard)
  async updateAppointment(
    @Request() req,
    @Param('id') appointmentId: string,
    @Body()
    updateDto: {
      appointmentDate?: string;
      status?: AppointmentStatus;
      notes?: string;
    },
  ) {
    const data: any = { ...updateDto };
    if (updateDto.appointmentDate) {
      data.appointmentDate = new Date(updateDto.appointmentDate);
    }

    return this.appointmentsService.updateAppointment(
      appointmentId,
      req.user.userId,
      data,
    );
  }

  // Cancel appointment
  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async cancelAppointment(
    @Request() req,
    @Param('id') appointmentId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.appointmentsService.cancelAppointment(
      appointmentId,
      req.user.userId,
      body?.reason,
    );
  }

  // Confirm appointment (practitioner only)
  @Post(':id/confirm')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async confirmAppointment(@Request() req, @Param('id') appointmentId: string) {
    return this.appointmentsService.confirmAppointment(
      appointmentId,
      req.user.userId,
    );
  }

  // Complete appointment (practitioner only)
  @Post(':id/complete')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async completeAppointment(@Request() req, @Param('id') appointmentId: string) {
    return this.appointmentsService.completeAppointment(
      appointmentId,
      req.user.userId,
    );
  }
}
