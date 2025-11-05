import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HealthScoreCalculator } from './health-score.calculator';
import { QuestionnaireResponseDto } from './dto/questionnaire-response.dto';
import { UserRole } from '@prisma/client';

@Injectable()
export class QuestionnaireService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly healthScoreCalculator: HealthScoreCalculator,
  ) {}

  /**
   * Submit questionnaire and calculate health score
   */
  async submitQuestionnaire(userId: string, userRole: UserRole, response: QuestionnaireResponseDto) {
    // Only clients can submit questionnaires
    if (userRole !== UserRole.CLIENT) {
      throw new ForbiddenException('Only clients can submit health questionnaires');
    }

    // Get client profile
    const clientProfile = await this.prisma.clientProfile.findUnique({
      where: { userId },
    });

    if (!clientProfile) {
      throw new NotFoundException('Client profile not found');
    }

    // Calculate health score
    const healthScore = this.healthScoreCalculator.calculate(response);

    // Update client profile with questionnaire data and score
    const updatedProfile = await this.prisma.clientProfile.update({
      where: { userId },
      data: {
        questionnaireCompleted: true,
        questionnaireData: response as any,
        currentScore: healthScore.totalScore,
        currentStatus: healthScore.status,
        domainScores: healthScore.domainScores as any,
      },
      select: {
        id: true,
        questionnaireCompleted: true,
        currentScore: true,
        currentStatus: true,
        domainScores: true,
      },
    });

    return {
      success: true,
      data: {
        profile: updatedProfile,
        healthScore,
      },
    };
  }

  /**
   * Get current health score
   */
  async getHealthScore(userId: string, userRole: UserRole) {
    if (userRole !== UserRole.CLIENT) {
      throw new ForbiddenException('Only clients have health scores');
    }

    const clientProfile = await this.prisma.clientProfile.findUnique({
      where: { userId },
      select: {
        questionnaireCompleted: true,
        currentScore: true,
        currentStatus: true,
        domainScores: true,
        questionnaireData: true,
      },
    });

    if (!clientProfile) {
      throw new NotFoundException('Client profile not found');
    }

    if (!clientProfile.questionnaireCompleted) {
      return {
        success: true,
        data: {
          completed: false,
          message: 'Questionnaire not completed yet',
        },
      };
    }

    return {
      success: true,
      data: {
        completed: true,
        currentScore: clientProfile.currentScore,
        currentStatus: clientProfile.currentStatus,
        domainScores: clientProfile.domainScores,
      },
    };
  }

  /**
   * Get top 3 wellness levers based on domain scores
   */
  async getTopLevers(userId: string, userRole: UserRole) {
    if (userRole !== UserRole.CLIENT) {
      throw new ForbiddenException('Only clients have wellness levers');
    }

    const clientProfile = await this.prisma.clientProfile.findUnique({
      where: { userId },
      select: {
        domainScores: true,
        questionnaireCompleted: true,
      },
    });

    if (!clientProfile || !clientProfile.questionnaireCompleted) {
      return {
        success: true,
        data: {
          levers: [],
        },
      };
    }

    const domainScores = clientProfile.domainScores as any;

    // Identify lowest scoring domains (most room for improvement)
    const domains = [
      { name: 'physical', score: domainScores.physical, lever: 'Improve sleep quality and manage pain' },
      { name: 'mental', score: domainScores.mental, lever: 'Manage stress and anxiety levels' },
      { name: 'lifestyle', score: domainScores.lifestyle, lever: 'Increase physical activity' },
      { name: 'social', score: domainScores.social, lever: 'Strengthen social connections' },
    ];

    // Sort by score (lowest first) and take top 3
    const topLevers = domains
      .sort((a, b) => a.score - b.score)
      .slice(0, 3)
      .map((d) => d.lever);

    return {
      success: true,
      data: {
        levers: topLevers,
      },
    };
  }
}
