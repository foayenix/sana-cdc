import { Injectable, Logger, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DayOfWeek, TimeOffStatus } from '@prisma/client';

export interface CreateAvailabilitySlotDto {
  practitionerId: string;
  dayOfWeek: DayOfWeek;
  startTime: string;
  endTime: string;
  effectiveFrom?: Date;
  effectiveTo?: Date;
  label?: string;
}

export interface UpdateAvailabilitySlotDto {
  dayOfWeek?: DayOfWeek;
  startTime?: string;
  endTime?: string;
  effectiveFrom?: Date;
  effectiveTo?: Date;
  label?: string;
  isActive?: boolean;
}

export interface CreateTimeOffDto {
  practitionerId: string;
  startDate: Date;
  endDate: Date;
  reason?: string;
}

export interface CreateAvailabilityOverrideDto {
  practitionerId: string;
  date: Date;
  startTime?: string;
  endTime?: string;
  reason?: string;
  isAvailable: boolean;
}

export interface GetAvailableSlotsDto {
  practitionerId: string;
  startDate: Date;
  endDate: Date;
  sessionDuration: number; // minutes
}

@Injectable()
export class AvailabilityService {
  private readonly logger = new Logger(AvailabilityService.name);

  constructor(private prisma: PrismaService) {}

  async createAvailabilitySlot(dto: CreateAvailabilitySlotDto) {
    const { practitionerId, dayOfWeek, startTime, endTime, effectiveFrom, effectiveTo, label } = dto;

    this.validateTimeFormat(startTime);
    this.validateTimeFormat(endTime);

    if (startTime >= endTime) {
      throw new BadRequestException('Start time must be before end time');
    }

    const slot = await this.prisma.availabilitySlot.create({
      data: { practitionerId, dayOfWeek, startTime, endTime, effectiveFrom, effectiveTo, label },
    });

    this.logger.log('Created availability slot: ' + slot.id);
    return slot;
  }

  async getAvailabilitySlots(practitionerId: string, activeOnly = true) {
    const slots = await this.prisma.availabilitySlot.findMany({
      where: { practitionerId, ...(activeOnly && { isActive: true }) },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
    });
    return slots;
  }

  async updateAvailabilitySlot(slotId: string, practitionerId: string, dto: UpdateAvailabilitySlotDto) {
    const slot = await this.prisma.availabilitySlot.findUnique({ where: { id: slotId } });
    
    if (!slot) throw new NotFoundException('Availability slot not found');
    if (slot.practitionerId !== practitionerId) throw new ForbiddenException('Access denied');

    if (dto.startTime) this.validateTimeFormat(dto.startTime);
    if (dto.endTime) this.validateTimeFormat(dto.endTime);

    return await this.prisma.availabilitySlot.update({ where: { id: slotId }, data: dto });
  }

  async deleteAvailabilitySlot(slotId: string, practitionerId: string) {
    const slot = await this.prisma.availabilitySlot.findUnique({ where: { id: slotId } });
    
    if (!slot) throw new NotFoundException('Availability slot not found');
    if (slot.practitionerId !== practitionerId) throw new ForbiddenException('Access denied');

    await this.prisma.availabilitySlot.delete({ where: { id: slotId } });
    return { success: true };
  }

  async bulkCreateAvailabilitySlots(slots: CreateAvailabilitySlotDto[]) {
    return await this.prisma.availabilitySlot.createMany({ data: slots });
  }

  async createTimeOff(dto: CreateTimeOffDto) {
    const { practitionerId, startDate, endDate, reason } = dto;

    if (startDate >= endDate) {
      throw new BadRequestException('Start date must be before end date');
    }

    const timeOff = await this.prisma.timeOff.create({
      data: { practitionerId, startDate, endDate, reason, status: TimeOffStatus.PENDING },
    });

    this.logger.log('Time off requested: ' + timeOff.id);
    return timeOff;
  }

  async getTimeOffs(practitionerId: string, status?: TimeOffStatus) {
    return await this.prisma.timeOff.findMany({
      where: { practitionerId, ...(status && { status }) },
      orderBy: { startDate: 'desc' },
    });
  }

  async updateTimeOffStatus(timeOffId: string, status: TimeOffStatus, approvedBy: string) {
    return await this.prisma.timeOff.update({
      where: { id: timeOffId },
      data: { status, approvedBy, approvedAt: new Date() },
    });
  }

  async createAvailabilityOverride(dto: CreateAvailabilityOverrideDto) {
    const { practitionerId, date, startTime, endTime, reason, isAvailable } = dto;

    if (startTime) this.validateTimeFormat(startTime);
    if (endTime) this.validateTimeFormat(endTime);

    const existing = await this.prisma.availabilityOverride.findFirst({
      where: {
        practitionerId,
        date: { gte: this.getStartOfDay(date), lte: this.getEndOfDay(date) },
      },
    });

    if (existing) {
      return await this.prisma.availabilityOverride.update({
        where: { id: existing.id },
        data: { startTime, endTime, reason, isAvailable },
      });
    }

    return await this.prisma.availabilityOverride.create({
      data: { practitionerId, date, startTime, endTime, reason, isAvailable },
    });
  }

  async getAvailabilityOverrides(practitionerId: string, startDate: Date, endDate: Date) {
    return await this.prisma.availabilityOverride.findMany({
      where: { practitionerId, date: { gte: startDate, lte: endDate } },
      orderBy: { date: 'asc' },
    });
  }

  private validateTimeFormat(time: string) {
    const regex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
    if (!regex.test(time)) {
      throw new BadRequestException('Invalid time format: ' + time + '. Use HH:MM');
    }
  }

  private getDayOfWeek(date: Date): DayOfWeek {
    const days = [
      DayOfWeek.SUNDAY, DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY,
      DayOfWeek.THURSDAY, DayOfWeek.FRIDAY, DayOfWeek.SATURDAY,
    ];
    return days[date.getDay()];
  }

  private isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate();
  }

  private parseTime(time: string): number {
    const parts = time.split(':').map(Number);
    return parts[0] * 60 + parts[1];
  }

  private formatTime(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    const h = hours.toString().padStart(2, '0');
    const m = mins.toString().padStart(2, '0');
    return h + ':' + m;
  }

  private getStartOfDay(date: Date): Date {
    const d = new Date(date);
    d.setHours(0, 0, 0, 0);
    return d;
  }

  private getEndOfDay(date: Date): Date {
    const d = new Date(date);
    d.setHours(23, 59, 59, 999);
    return d;
  }
}
