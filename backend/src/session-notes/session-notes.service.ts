import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface CreateSessionNoteDto {
  appointmentId: string;
  notes: string;
  privateNotes?: string;
  recommendations?: string;
  followUpRequired?: boolean;
  followUpDate?: Date;
}

interface UpdateSessionNoteDto {
  notes?: string;
  privateNotes?: string;
  recommendations?: string;
  followUpRequired?: boolean;
  followUpDate?: Date;
}

@Injectable()
export class SessionNotesService {
  constructor(private readonly prisma: PrismaService) {}

  // Create session note (practitioner only, after appointment)
  async createSessionNote(
    practitionerId: string,
    createDto: CreateSessionNoteDto,
  ) {
    // Verify appointment exists and belongs to practitioner
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: createDto.appointmentId },
      include: {
        sessionNotes: true,
      },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    if (appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('You can only create notes for your own appointments');
    }

    // Check appointment is completed
    if (appointment.status !== 'COMPLETED') {
      throw new BadRequestException('Can only create notes for completed appointments');
    }

    // Check if notes already exist
    if (appointment.sessionNotes) {
      throw new BadRequestException('Session notes already exist for this appointment');
    }

    const sessionNote = await this.prisma.sessionNote.create({
      data: {
        appointmentId: createDto.appointmentId,
        notes: createDto.notes,
        privateNotes: createDto.privateNotes,
        recommendations: createDto.recommendations,
        followUpRequired: createDto.followUpRequired || false,
        followUpDate: createDto.followUpDate,
      },
      include: {
        appointment: {
          include: {
            client: {
              include: {
                user: true,
              },
            },
            sessionType: true,
          },
        },
      },
    });

    return sessionNote;
  }

  // Get session note by ID
  async getSessionNote(sessionNoteId: string, userId: string) {
    const sessionNote = await this.prisma.sessionNote.findUnique({
      where: { id: sessionNoteId },
      include: {
        appointment: {
          include: {
            client: {
              include: { user: true },
            },
            practitioner: {
              include: { user: true },
            },
            sessionType: true,
          },
        },
      },
    });

    if (!sessionNote) {
      throw new NotFoundException('Session note not found');
    }

    // Verify user has access (practitioner or client)
    if (
      sessionNote.appointment.practitionerId !== userId &&
      sessionNote.appointment.clientId !== userId
    ) {
      throw new ForbiddenException('Access denied');
    }

    // If client is viewing, remove private notes
    if (sessionNote.appointment.clientId === userId) {
      return {
        ...sessionNote,
        privateNotes: undefined,
      };
    }

    return sessionNote;
  }

  // Get all session notes for a practitioner
  async getPractitionerSessionNotes(practitionerId: string) {
    const sessionNotes = await this.prisma.sessionNote.findMany({
      where: {
        appointment: {
          practitionerId,
        },
      },
      include: {
        appointment: {
          include: {
            client: {
              include: { user: true },
            },
            sessionType: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return sessionNotes;
  }

  // Get all session notes for a client
  async getClientSessionNotes(clientId: string) {
    const sessionNotes = await this.prisma.sessionNote.findMany({
      where: {
        appointment: {
          clientId,
        },
      },
      include: {
        appointment: {
          include: {
            practitioner: {
              include: { user: true },
            },
            sessionType: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Remove private notes for client view
    return sessionNotes.map((note) => ({
      ...note,
      privateNotes: undefined,
    }));
  }

  // Update session note (practitioner only)
  async updateSessionNote(
    sessionNoteId: string,
    practitionerId: string,
    updateDto: UpdateSessionNoteDto,
  ) {
    const sessionNote = await this.prisma.sessionNote.findUnique({
      where: { id: sessionNoteId },
      include: {
        appointment: true,
      },
    });

    if (!sessionNote) {
      throw new NotFoundException('Session note not found');
    }

    if (sessionNote.appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('You can only update your own session notes');
    }

    const updatedNote = await this.prisma.sessionNote.update({
      where: { id: sessionNoteId },
      data: updateDto,
      include: {
        appointment: {
          include: {
            client: {
              include: { user: true },
            },
            sessionType: true,
          },
        },
      },
    });

    return updatedNote;
  }

  // Delete session note (practitioner only)
  async deleteSessionNote(sessionNoteId: string, practitionerId: string) {
    const sessionNote = await this.prisma.sessionNote.findUnique({
      where: { id: sessionNoteId },
      include: {
        appointment: true,
      },
    });

    if (!sessionNote) {
      throw new NotFoundException('Session note not found');
    }

    if (sessionNote.appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('You can only delete your own session notes');
    }

    await this.prisma.sessionNote.delete({
      where: { id: sessionNoteId },
    });

    return { success: true, message: 'Session note deleted' };
  }
}
