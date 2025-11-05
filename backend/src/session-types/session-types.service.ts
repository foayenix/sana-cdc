import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface CreateSessionTypeDto {
  name: string;
  description: string;
  durationMinutes: number;
  priceGBP: number;
  isActive?: boolean;
}

interface UpdateSessionTypeDto {
  name?: string;
  description?: string;
  durationMinutes?: number;
  priceGBP?: number;
  isActive?: boolean;
}

@Injectable()
export class SessionTypesService {
  constructor(private readonly prisma: PrismaService) {}

  // Create a new session type
  async createSessionType(userId: string, createDto: CreateSessionTypeDto) {
    // Verify user is a practitioner
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { practitionerProfile: true },
    });

    if (!user || !user.practitionerProfile) {
      throw new ForbiddenException('Only practitioners can create session types');
    }

    const sessionType = await this.prisma.sessionType.create({
      data: {
        practitionerId: userId,
        name: createDto.name,
        description: createDto.description,
        durationMinutes: createDto.durationMinutes,
        priceGBP: createDto.priceGBP,
        isActive: createDto.isActive ?? true,
      },
    });

    return {
      success: true,
      sessionType,
    };
  }

  // Get all session types for a practitioner
  async getSessionTypes(practitionerId: string, includeInactive = false) {
    const where: any = { practitionerId };

    if (!includeInactive) {
      where.isActive = true;
    }

    const sessionTypes = await this.prisma.sessionType.findMany({
      where,
      orderBy: { durationMinutes: 'asc' },
    });

    return sessionTypes;
  }

  // Get single session type by ID
  async getSessionTypeById(sessionTypeId: string) {
    const sessionType = await this.prisma.sessionType.findUnique({
      where: { id: sessionTypeId },
      include: {
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
                profilePhoto: true,
              },
            },
          },
        },
      },
    });

    if (!sessionType) {
      throw new NotFoundException('Session type not found');
    }

    return sessionType;
  }

  // Update session type
  async updateSessionType(
    userId: string,
    sessionTypeId: string,
    updateDto: UpdateSessionTypeDto,
  ) {
    const sessionType = await this.prisma.sessionType.findUnique({
      where: { id: sessionTypeId },
    });

    if (!sessionType) {
      throw new NotFoundException('Session type not found');
    }

    if (sessionType.practitionerId !== userId) {
      throw new ForbiddenException(
        'You can only update your own session types',
      );
    }

    const updated = await this.prisma.sessionType.update({
      where: { id: sessionTypeId },
      data: updateDto,
    });

    return {
      success: true,
      sessionType: updated,
    };
  }

  // Delete session type (soft delete by setting isActive to false)
  async deleteSessionType(userId: string, sessionTypeId: string) {
    const sessionType = await this.prisma.sessionType.findUnique({
      where: { id: sessionTypeId },
    });

    if (!sessionType) {
      throw new NotFoundException('Session type not found');
    }

    if (sessionType.practitionerId !== userId) {
      throw new ForbiddenException(
        'You can only delete your own session types',
      );
    }

    // Soft delete by setting isActive to false
    await this.prisma.sessionType.update({
      where: { id: sessionTypeId },
      data: { isActive: false },
    });

    return {
      success: true,
      message: 'Session type deactivated successfully',
    };
  }
}
