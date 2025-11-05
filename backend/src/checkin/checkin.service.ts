import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HealthScoreCalculator } from '../questionnaire/health-score.calculator';
import { CreateCheckinDto } from './dto/create-checkin.dto';
import { UserRole } from '@prisma/client';

@Injectable()
export class CheckinService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly healthScoreCalculator: HealthScoreCalculator,
  ) {}

  /**
   * Submit daily check-in
   */
  async submitCheckin(userId: string, userRole: UserRole, checkinDto: CreateCheckinDto) {
    // Only clients can submit check-ins
    if (userRole !== UserRole.CLIENT) {
      throw new ForbiddenException('Only clients can submit daily check-ins');
    }

    // Get client profile
    const clientProfile = await this.prisma.clientProfile.findUnique({
      where: { userId },
    });

    if (!clientProfile) {
      throw new NotFoundException('Client profile not found');
    }

    // Check if check-in already exists for today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const existingCheckin = await this.prisma.dailyCheckin.findUnique({
      where: {
        clientId_date: {
          clientId: clientProfile.id,
          date: today,
        },
      },
    });

    if (existingCheckin) {
      throw new ConflictException('Check-in already submitted for today');
    }

    // Create check-in
    const checkin = await this.prisma.dailyCheckin.create({
      data: {
        clientId: clientProfile.id,
        date: today,
        sleepQuality: checkinDto.sleepQuality,
        energyLevel: checkinDto.energyLevel,
        mood: checkinDto.mood,
        stressLevel: checkinDto.stressLevel,
      },
    });

    // Update health score with check-in data
    const newScore = this.healthScoreCalculator.updateScoreWithCheckin(
      clientProfile.currentScore,
      checkinDto,
    );

    const newStatus = this.getStatusFromScore(newScore);

    await this.prisma.clientProfile.update({
      where: { id: clientProfile.id },
      data: {
        currentScore: newScore,
        currentStatus: newStatus,
      },
    });

    return {
      success: true,
      data: {
        checkin,
        updatedScore: newScore,
        updatedStatus: newStatus,
      },
    };
  }

  /**
   * Get check-in history
   */
  async getCheckinHistory(userId: string, userRole: UserRole, days: number = 30) {
    if (userRole !== UserRole.CLIENT) {
      throw new ForbiddenException('Only clients have check-in history');
    }

    const clientProfile = await this.prisma.clientProfile.findUnique({
      where: { userId },
    });

    if (!clientProfile) {
      throw new NotFoundException('Client profile not found');
    }

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const checkins = await this.prisma.dailyCheckin.findMany({
      where: {
        clientId: clientProfile.id,
        date: {
          gte: startDate,
        },
      },
      orderBy: {
        date: 'desc',
      },
    });

    return {
      success: true,
      data: {
        checkins,
        count: checkins.length,
      },
    };
  }

  /**
   * Get check-in completion rate
   */
  async getCompletionRate(userId: string, userRole: UserRole, days: number = 30) {
    if (userRole !== UserRole.CLIENT) {
      throw new ForbiddenException('Only clients have check-in data');
    }

    const clientProfile = await this.prisma.clientProfile.findUnique({
      where: { userId },
    });

    if (!clientProfile) {
      throw new NotFoundException('Client profile not found');
    }

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const checkinCount = await this.prisma.dailyCheckin.count({
      where: {
        clientId: clientProfile.id,
        date: {
          gte: startDate,
        },
      },
    });

    const completionRate = (checkinCount / days) * 100;

    return {
      success: true,
      data: {
        completionRate: Math.round(completionRate),
        checkinsDone: checkinCount,
        totalDays: days,
      },
    };
  }

  /**
   * Helper method to get status from score
   */
  private getStatusFromScore(score: number): string {
    if (score >= 91) return 'RADIANT';
    if (score >= 76) return 'THRIVING';
    if (score >= 61) return 'BALANCED';
    if (score >= 41) return 'REBUILDING';
    return 'NEEDS_SUPPORT';
  }
}
