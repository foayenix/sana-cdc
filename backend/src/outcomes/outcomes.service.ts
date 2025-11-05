import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface CreateOutcomeDto {
  appointmentId: string;
  outcomeScore: number; // 1-5 scale
  improvementNotes?: string;
  goalsAchieved?: string[];
  nextSteps?: string;
}

interface UpdateOutcomeDto {
  outcomeScore?: number;
  improvementNotes?: string;
  goalsAchieved?: string[];
  nextSteps?: string;
}

@Injectable()
export class OutcomesService {
  constructor(private readonly prisma: PrismaService) {}

  // Create client outcome (practitioner only, after session)
  async createOutcome(practitionerId: string, createDto: CreateOutcomeDto) {
    // Verify appointment exists and belongs to practitioner
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: createDto.appointmentId },
      include: {
        outcome: true,
        client: {
          include: {
            clientProfile: true,
          },
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    if (appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('You can only create outcomes for your own appointments');
    }

    // Check appointment is completed
    if (appointment.status !== 'COMPLETED') {
      throw new BadRequestException('Can only create outcomes for completed appointments');
    }

    // Check if outcome already exists
    if (appointment.outcome) {
      throw new BadRequestException('Outcome already exists for this appointment');
    }

    // Validate outcome score (1-5)
    if (createDto.outcomeScore < 1 || createDto.outcomeScore > 5) {
      throw new BadRequestException('Outcome score must be between 1 and 5');
    }

    const outcome = await this.prisma.clientOutcome.create({
      data: {
        appointmentId: createDto.appointmentId,
        outcomeScore: createDto.outcomeScore,
        improvementNotes: createDto.improvementNotes,
        goalsAchieved: createDto.goalsAchieved || [],
        nextSteps: createDto.nextSteps,
      },
      include: {
        appointment: {
          include: {
            client: {
              include: {
                user: true,
                clientProfile: true,
              },
            },
            practitioner: {
              include: {
                user: true,
              },
            },
            sessionType: true,
          },
        },
      },
    });

    return outcome;
  }

  // Get outcome by ID
  async getOutcome(outcomeId: string, userId: string) {
    const outcome = await this.prisma.clientOutcome.findUnique({
      where: { id: outcomeId },
      include: {
        appointment: {
          include: {
            client: {
              include: {
                user: true,
                clientProfile: true,
              },
            },
            practitioner: {
              include: {
                user: true,
              },
            },
            sessionType: true,
          },
        },
      },
    });

    if (!outcome) {
      throw new NotFoundException('Outcome not found');
    }

    // Verify user has access (practitioner or client)
    if (
      outcome.appointment.practitionerId !== userId &&
      outcome.appointment.clientId !== userId
    ) {
      throw new ForbiddenException('Access denied');
    }

    return outcome;
  }

  // Get all outcomes for a practitioner
  async getPractitionerOutcomes(practitionerId: string) {
    const outcomes = await this.prisma.clientOutcome.findMany({
      where: {
        appointment: {
          practitionerId,
        },
      },
      include: {
        appointment: {
          include: {
            client: {
              include: {
                user: true,
                clientProfile: true,
              },
            },
            sessionType: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return outcomes;
  }

  // Get all outcomes for a client
  async getClientOutcomes(clientId: string) {
    const outcomes = await this.prisma.clientOutcome.findMany({
      where: {
        appointment: {
          clientId,
        },
      },
      include: {
        appointment: {
          include: {
            practitioner: {
              include: {
                user: true,
              },
            },
            sessionType: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return outcomes;
  }

  // Update outcome (practitioner only)
  async updateOutcome(
    outcomeId: string,
    practitionerId: string,
    updateDto: UpdateOutcomeDto,
  ) {
    const outcome = await this.prisma.clientOutcome.findUnique({
      where: { id: outcomeId },
      include: {
        appointment: true,
      },
    });

    if (!outcome) {
      throw new NotFoundException('Outcome not found');
    }

    if (outcome.appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('You can only update your own outcomes');
    }

    // Validate outcome score if provided
    if (
      updateDto.outcomeScore &&
      (updateDto.outcomeScore < 1 || updateDto.outcomeScore > 5)
    ) {
      throw new BadRequestException('Outcome score must be between 1 and 5');
    }

    const updatedOutcome = await this.prisma.clientOutcome.update({
      where: { id: outcomeId },
      data: updateDto,
      include: {
        appointment: {
          include: {
            client: {
              include: {
                user: true,
                clientProfile: true,
              },
            },
            sessionType: true,
          },
        },
      },
    });

    return updatedOutcome;
  }

  // Get outcome statistics for a practitioner
  async getPractitionerOutcomeStats(practitionerId: string) {
    const outcomes = await this.prisma.clientOutcome.findMany({
      where: {
        appointment: {
          practitionerId,
        },
      },
      select: {
        outcomeScore: true,
      },
    });

    if (outcomes.length === 0) {
      return {
        totalOutcomes: 0,
        averageScore: 0,
        distribution: {
          '1': 0,
          '2': 0,
          '3': 0,
          '4': 0,
          '5': 0,
        },
      };
    }

    const distribution = {
      '1': 0,
      '2': 0,
      '3': 0,
      '4': 0,
      '5': 0,
    };

    let totalScore = 0;

    outcomes.forEach((outcome) => {
      const score = outcome.outcomeScore.toString();
      distribution[score as keyof typeof distribution]++;
      totalScore += outcome.outcomeScore;
    });

    return {
      totalOutcomes: outcomes.length,
      averageScore: totalScore / outcomes.length,
      distribution,
    };
  }

  // Delete outcome (practitioner only)
  async deleteOutcome(outcomeId: string, practitionerId: string) {
    const outcome = await this.prisma.clientOutcome.findUnique({
      where: { id: outcomeId },
      include: {
        appointment: true,
      },
    });

    if (!outcome) {
      throw new NotFoundException('Outcome not found');
    }

    if (outcome.appointment.practitionerId !== practitionerId) {
      throw new ForbiddenException('You can only delete your own outcomes');
    }

    await this.prisma.clientOutcome.delete({
      where: { id: outcomeId },
    });

    return { success: true, message: 'Outcome deleted' };
  }
}
