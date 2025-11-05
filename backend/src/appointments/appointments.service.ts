import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AppointmentStatus } from '@prisma/client';

interface CreateAppointmentDto {
  practitionerId: string;
  sessionTypeId: string;
  appointmentDate: Date;
  notes?: string;
}

interface UpdateAppointmentDto {
  appointmentDate?: Date;
  status?: AppointmentStatus;
  notes?: string;
}

@Injectable()
export class AppointmentsService {
  constructor(private readonly prisma: PrismaService) {}

  // Create appointment (client books with practitioner)
  async createAppointment(clientId: string, createDto: CreateAppointmentDto) {
    // Verify practitioner exists and is verified
    const practitioner = await this.prisma.practitionerProfile.findUnique({
      where: { userId: createDto.practitionerId },
    });

    if (!practitioner) {
      throw new NotFoundException('Practitioner not found');
    }

    if (practitioner.verificationStatus !== 'VERIFIED') {
      throw new BadRequestException('Practitioner is not verified');
    }

    // Verify session type exists and belongs to practitioner
    const sessionType = await this.prisma.sessionType.findUnique({
      where: { id: createDto.sessionTypeId },
    });

    if (!sessionType) {
      throw new NotFoundException('Session type not found');
    }

    if (sessionType.practitionerId !== createDto.practitionerId) {
      throw new BadRequestException(
        'Session type does not belong to this practitioner',
      );
    }

    if (!sessionType.isActive) {
      throw new BadRequestException('Session type is not active');
    }

    // Check if appointment time is in the future
    if (new Date(createDto.appointmentDate) <= new Date()) {
      throw new BadRequestException('Appointment date must be in the future');
    }

    // Check for conflicts (practitioner already booked at this time)
    const conflictingAppointment = await this.prisma.appointment.findFirst({
      where: {
        practitionerId: createDto.practitionerId,
        appointmentDate: createDto.appointmentDate,
        status: {
          in: ['SCHEDULED', 'CONFIRMED'],
        },
      },
    });

    if (conflictingAppointment) {
      throw new BadRequestException(
        'Practitioner is not available at this time',
      );
    }

    // Create appointment
    const appointment = await this.prisma.appointment.create({
      data: {
        clientId,
        practitionerId: createDto.practitionerId,
        sessionTypeId: createDto.sessionTypeId,
        appointmentDate: createDto.appointmentDate,
        status: 'SCHEDULED',
        notes: createDto.notes,
      },
      include: {
        sessionType: true,
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
                profilePhoto: true,
              },
            },
          },
        },
        client: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        },
      },
    });

    return appointment;
  }

  // Get all appointments for a user (client or practitioner)
  async getAppointments(
    userId: string,
    role: 'CLIENT' | 'PRACTITIONER',
    filters?: {
      status?: AppointmentStatus;
      fromDate?: Date;
      toDate?: Date;
    },
  ) {
    const where: any = {
      ...(role === 'CLIENT' ? { clientId: userId } : { practitionerId: userId }),
    };

    if (filters?.status) {
      where.status = filters.status;
    }

    if (filters?.fromDate || filters?.toDate) {
      where.appointmentDate = {};
      if (filters.fromDate) {
        where.appointmentDate.gte = filters.fromDate;
      }
      if (filters.toDate) {
        where.appointmentDate.lte = filters.toDate;
      }
    }

    const appointments = await this.prisma.appointment.findMany({
      where,
      include: {
        sessionType: true,
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
                profilePhoto: true,
              },
            },
          },
        },
        client: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        },
      },
      orderBy: {
        appointmentDate: 'asc',
      },
    });

    return appointments;
  }

  // Get single appointment by ID
  async getAppointmentById(appointmentId: string, userId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        sessionType: true,
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
                profilePhoto: true,
              },
            },
          },
        },
        client: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
              },
            },
            clientProfile: true,
          },
        },
        sessionNotes: true,
        outcome: true,
      },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Verify user is part of this appointment
    if (
      appointment.clientId !== userId &&
      appointment.practitionerId !== userId
    ) {
      throw new ForbiddenException('Access denied');
    }

    return appointment;
  }

  // Update appointment (reschedule or change status)
  async updateAppointment(
    appointmentId: string,
    userId: string,
    updateDto: UpdateAppointmentDto,
  ) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Verify user is part of this appointment
    if (
      appointment.clientId !== userId &&
      appointment.practitionerId !== userId
    ) {
      throw new ForbiddenException('Access denied');
    }

    // Validate status transitions
    if (updateDto.status) {
      this.validateStatusTransition(appointment.status, updateDto.status);
    }

    // If rescheduling, check for conflicts
    if (updateDto.appointmentDate) {
      if (new Date(updateDto.appointmentDate) <= new Date()) {
        throw new BadRequestException('Appointment date must be in the future');
      }

      const conflictingAppointment = await this.prisma.appointment.findFirst({
        where: {
          practitionerId: appointment.practitionerId,
          appointmentDate: updateDto.appointmentDate,
          status: {
            in: ['SCHEDULED', 'CONFIRMED'],
          },
          id: {
            not: appointmentId,
          },
        },
      });

      if (conflictingAppointment) {
        throw new BadRequestException(
          'Practitioner is not available at this time',
        );
      }
    }

    const updatedAppointment = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: updateDto,
      include: {
        sessionType: true,
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
                profilePhoto: true,
              },
            },
          },
        },
        client: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        },
      },
    });

    return updatedAppointment;
  }

  // Cancel appointment
  async cancelAppointment(appointmentId: string, userId: string, reason?: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Verify user is part of this appointment
    if (
      appointment.clientId !== userId &&
      appointment.practitionerId !== userId
    ) {
      throw new ForbiddenException('Access denied');
    }

    // Can only cancel scheduled or confirmed appointments
    if (!['SCHEDULED', 'CONFIRMED'].includes(appointment.status)) {
      throw new BadRequestException(
        `Cannot cancel appointment with status: ${appointment.status}`,
      );
    }

    // Check cancellation policy (e.g., 24 hours notice)
    const hoursUntilAppointment =
      (new Date(appointment.appointmentDate).getTime() - new Date().getTime()) /
      (1000 * 60 * 60);

    let cancellationNotes = reason || 'Cancelled by user';
    if (hoursUntilAppointment < 24) {
      cancellationNotes += ' (Less than 24 hours notice)';
    }

    const cancelledAppointment = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        status: 'CANCELLED',
        notes: appointment.notes
          ? `${appointment.notes}\n\nCancellation: ${cancellationNotes}`
          : cancellationNotes,
      },
      include: {
        sessionType: true,
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        },
      },
    });

    return cancelledAppointment;
  }

  // Confirm appointment (practitioner confirms)
  async confirmAppointment(appointmentId: string, practitionerId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    if (appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('Access denied');
    }

    if (appointment.status !== 'SCHEDULED') {
      throw new BadRequestException(
        'Only scheduled appointments can be confirmed',
      );
    }

    const confirmedAppointment = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: 'CONFIRMED' },
      include: {
        client: {
          include: {
            user: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        },
        sessionType: true,
      },
    });

    return confirmedAppointment;
  }

  // Mark appointment as completed (practitioner)
  async completeAppointment(appointmentId: string, practitionerId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    if (appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('Access denied');
    }

    if (appointment.status !== 'CONFIRMED') {
      throw new BadRequestException('Only confirmed appointments can be completed');
    }

    // Check if appointment date has passed
    if (new Date(appointment.appointmentDate) > new Date()) {
      throw new BadRequestException('Cannot complete future appointment');
    }

    const completedAppointment = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: 'COMPLETED' },
      include: {
        client: {
          include: {
            user: true,
          },
        },
        sessionType: true,
      },
    });

    return completedAppointment;
  }

  // Get available time slots for a practitioner on a specific date
  async getAvailableSlots(practitionerId: string, date: Date) {
    // Get practitioner's availability
    const practitioner = await this.prisma.practitionerProfile.findUnique({
      where: { userId: practitionerId },
    });

    if (!practitioner) {
      throw new NotFoundException('Practitioner not found');
    }

    const availabilityData = practitioner.availabilityData as any[];
    if (!availabilityData || availabilityData.length === 0) {
      return [];
    }

    // Get day of week (0 = Sunday)
    const dayOfWeek = date.getDay();

    // Find availability for this day
    const dayAvailability = availabilityData.filter(
      (slot) => slot.dayOfWeek === dayOfWeek,
    );

    if (dayAvailability.length === 0) {
      return [];
    }

    // Get existing appointments for this day
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const existingAppointments = await this.prisma.appointment.findMany({
      where: {
        practitionerId,
        appointmentDate: {
          gte: startOfDay,
          lte: endOfDay,
        },
        status: {
          in: ['SCHEDULED', 'CONFIRMED'],
        },
      },
      include: {
        sessionType: true,
      },
    });

    // Generate available slots (30-minute intervals)
    const availableSlots: any[] = [];

    for (const slot of dayAvailability) {
      const [startHour, startMinute] = slot.startTime.split(':').map(Number);
      const [endHour, endMinute] = slot.endTime.split(':').map(Number);

      let currentTime = new Date(date);
      currentTime.setHours(startHour, startMinute, 0, 0);

      const endTime = new Date(date);
      endTime.setHours(endHour, endMinute, 0, 0);

      while (currentTime < endTime) {
        // Check if this slot is already booked
        const isBooked = existingAppointments.some((apt) => {
          const aptStart = new Date(apt.appointmentDate);
          const aptEnd = new Date(aptStart);
          aptEnd.setMinutes(aptEnd.getMinutes() + apt.sessionType.durationMinutes);

          return currentTime >= aptStart && currentTime < aptEnd;
        });

        // Only add if not booked and not in the past
        if (!isBooked && currentTime > new Date()) {
          availableSlots.push({
            startTime: new Date(currentTime),
            available: true,
          });
        }

        // Move to next 30-minute slot
        currentTime = new Date(currentTime);
        currentTime.setMinutes(currentTime.getMinutes() + 30);
      }
    }

    return availableSlots;
  }

  // Validate status transitions
  private validateStatusTransition(
    currentStatus: AppointmentStatus,
    newStatus: AppointmentStatus,
  ) {
    const validTransitions: Record<AppointmentStatus, AppointmentStatus[]> = {
      SCHEDULED: ['CONFIRMED', 'CANCELLED'],
      CONFIRMED: ['COMPLETED', 'CANCELLED', 'NO_SHOW'],
      COMPLETED: [],
      CANCELLED: [],
      NO_SHOW: [],
    };

    if (!validTransitions[currentStatus]?.includes(newStatus)) {
      throw new BadRequestException(
        `Invalid status transition from ${currentStatus} to ${newStatus}`,
      );
    }
  }
}
