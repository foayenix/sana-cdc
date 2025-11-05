import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface SanaIndexBreakdown {
  credentialsScore: number;
  experienceScore: number;
  outcomesScore: number;
  totalScore: number;
}

@Injectable()
export class SanaIndexService {
  private readonly logger = new Logger(SanaIndexService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Calculate SANA Index for a practitioner
   * Total: 100 points
   * - Credentials: 30 points
   * - Experience: 30 points
   * - Outcomes: 40 points
   */
  async calculateSanaIndex(practitionerId: string): Promise<SanaIndexBreakdown> {
    const profile = await this.prisma.practitionerProfile.findUnique({
      where: { userId: practitionerId },
      include: {
        user: {
          include: {
            practitionerAppointments: {
              where: {
                status: 'COMPLETED',
              },
            },
          },
        },
      },
    });

    if (!profile) {
      throw new Error('Practitioner profile not found');
    }

    // Calculate each component
    const credentialsScore = this.calculateCredentialsScore(profile);
    const experienceScore = this.calculateExperienceScore(profile);
    const outcomesScore = await this.calculateOutcomesScore(practitionerId);

    const totalScore = Math.round(
      credentialsScore + experienceScore + outcomesScore,
    );

    this.logger.log(
      `SANA Index calculated for practitioner ${practitionerId}: ${totalScore} ` +
        `(Credentials: ${credentialsScore}, Experience: ${experienceScore}, Outcomes: ${outcomesScore})`,
    );

    return {
      credentialsScore: Math.round(credentialsScore),
      experienceScore: Math.round(experienceScore),
      outcomesScore: Math.round(outcomesScore),
      totalScore: Math.min(100, totalScore), // Cap at 100
    };
  }

  /**
   * Calculate Credentials Score (30 points max)
   * - Professional body: 10 pts
   * - Years of practice: up to 10 pts (1 pt per year, max 10)
   * - Qualifications: up to 10 pts (5 pts per qualification, max 10)
   */
  private calculateCredentialsScore(profile: any): number {
    let score = 0;

    // Professional body membership (10 pts)
    if (profile.professionalBody) {
      score += 10;
    }

    // Years of practice (up to 10 pts)
    const yearsScore = Math.min(profile.yearsOfPractice || 0, 10);
    score += yearsScore;

    // Qualifications (up to 10 pts, 5 pts each)
    const qualifications = profile.qualifications || [];
    const qualificationsScore = Math.min(
      qualifications.length * 5,
      10,
    );
    score += qualificationsScore;

    return Math.min(score, 30);
  }

  /**
   * Calculate Experience Score (30 points max)
   * - Total sessions completed: up to 20 pts (0.2 pt per session, max 20)
   * - Years of practice: up to 10 pts (1 pt per year, max 10)
   */
  private calculateExperienceScore(profile: any): number {
    let score = 0;

    // Total completed sessions (up to 20 pts)
    const completedSessions = profile.user.practitionerAppointments?.length || 0;
    const sessionsScore = Math.min(completedSessions * 0.2, 20);
    score += sessionsScore;

    // Years of practice (up to 10 pts)
    const yearsScore = Math.min(profile.yearsOfPractice || 0, 10);
    score += yearsScore;

    return Math.min(score, 30);
  }

  /**
   * Calculate Outcomes Score (40 points max)
   * - Average client outcome score: up to 25 pts
   * - Client improvement rate: up to 15 pts
   */
  private async calculateOutcomesScore(practitionerId: string): Promise<number> {
    // Get all client outcomes for this practitioner
    const outcomes = await this.prisma.clientOutcome.findMany({
      where: {
        appointment: {
          practitionerId,
          status: 'COMPLETED',
        },
      },
      include: {
        appointment: {
          include: {
            client: {
              include: {
                clientProfile: true,
              },
            },
          },
        },
      },
    });

    if (outcomes.length === 0) {
      // No outcomes yet, return 0
      return 0;
    }

    let outcomeScore = 0;

    // Average outcome score (up to 25 pts)
    // outcomeScore ranges 1-5, so we map it to 0-25
    const avgOutcome =
      outcomes.reduce((sum, o) => sum + o.outcomeScore, 0) / outcomes.length;
    const avgOutcomeScore = ((avgOutcome - 1) / 4) * 25; // Map 1-5 to 0-25
    outcomeScore += avgOutcomeScore;

    // Client improvement rate (up to 15 pts)
    // Calculate how many clients improved their health score after sessions
    const clientImprovements = await this.calculateClientImprovements(
      practitionerId,
    );
    const improvementRate = clientImprovements.improvementRate;
    const improvementScore = improvementRate * 15; // 0-1 range to 0-15 pts
    outcomeScore += improvementScore;

    return Math.min(outcomeScore, 40);
  }

  /**
   * Calculate client improvement rate
   * Returns percentage of clients who improved their health score
   */
  private async calculateClientImprovements(
    practitionerId: string,
  ): Promise<{ improvementRate: number; totalClients: number; improvedClients: number }> {
    // Get all unique clients who had sessions with this practitioner
    const appointments = await this.prisma.appointment.findMany({
      where: {
        practitionerId,
        status: 'COMPLETED',
      },
      include: {
        client: {
          include: {
            clientProfile: true,
          },
        },
      },
      orderBy: {
        appointmentDate: 'asc',
      },
    });

    if (appointments.length === 0) {
      return { improvementRate: 0, totalClients: 0, improvedClients: 0 };
    }

    // Group by client and check if their score improved
    const clientScoreChanges = new Map<string, { initial: number; final: number }>();

    for (const appointment of appointments) {
      const clientId = appointment.clientId;
      const currentScore = appointment.client.clientProfile?.currentScore || 0;

      if (!clientScoreChanges.has(clientId)) {
        clientScoreChanges.set(clientId, {
          initial: currentScore,
          final: currentScore,
        });
      } else {
        // Update final score
        const existing = clientScoreChanges.get(clientId)!;
        existing.final = currentScore;
      }
    }

    // Count how many clients improved
    let improvedCount = 0;
    for (const [_, scores] of clientScoreChanges) {
      if (scores.final > scores.initial) {
        improvedCount++;
      }
    }

    const totalClients = clientScoreChanges.size;
    const improvementRate = totalClients > 0 ? improvedCount / totalClients : 0;

    return {
      improvementRate,
      totalClients,
      improvedClients: improvedCount,
    };
  }

  /**
   * Update SANA Index in database
   */
  async updateSanaIndex(practitionerId: string): Promise<void> {
    const breakdown = await this.calculateSanaIndex(practitionerId);

    await this.prisma.practitionerProfile.update({
      where: { userId: practitionerId },
      data: {
        sanaIndexScore: breakdown.totalScore,
      },
    });

    this.logger.log(
      `SANA Index updated for practitioner ${practitionerId}: ${breakdown.totalScore}`,
    );
  }

  /**
   * Recalculate SANA Index for all practitioners
   * This should be run periodically (e.g., daily cron job)
   */
  async recalculateAllSanaIndexes(): Promise<void> {
    this.logger.log('Starting SANA Index recalculation for all practitioners...');

    const practitioners = await this.prisma.practitionerProfile.findMany({
      select: { userId: true },
    });

    let updated = 0;
    let failed = 0;

    for (const practitioner of practitioners) {
      try {
        await this.updateSanaIndex(practitioner.userId);
        updated++;
      } catch (error) {
        this.logger.error(
          `Failed to update SANA Index for practitioner ${practitioner.userId}`,
          error,
        );
        failed++;
      }
    }

    this.logger.log(
      `SANA Index recalculation complete. Updated: ${updated}, Failed: ${failed}`,
    );
  }
}
