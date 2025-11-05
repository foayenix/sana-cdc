import { Injectable } from '@nestjs/common';
import { QuestionnaireResponseDto } from './dto/questionnaire-response.dto';

export interface HealthScore {
  totalScore: number;
  status: string;
  domainScores: {
    physical: number;
    mental: number;
    lifestyle: number;
    social: number;
  };
}

@Injectable()
export class HealthScoreCalculator {
  /**
   * Calculate SANA Health Score from questionnaire response
   */
  calculate(response: QuestionnaireResponseDto): HealthScore {
    const physicalScore = this.calculatePhysicalScore(response);
    const mentalScore = this.calculateMentalScore(response);
    const lifestyleScore = this.calculateLifestyleScore(response);
    const socialScore = this.calculateSocialScore(response);

    const totalScore = Math.round(physicalScore + mentalScore + lifestyleScore + socialScore);
    const status = this.getStatusFromScore(totalScore);

    return {
      totalScore,
      status,
      domainScores: {
        physical: Math.round(physicalScore),
        mental: Math.round(mentalScore),
        lifestyle: Math.round(lifestyleScore),
        social: Math.round(socialScore),
      },
    };
  }

  /**
   * Calculate Physical Domain Score (25 points max)
   */
  private calculatePhysicalScore(response: QuestionnaireResponseDto): number {
    let score = 0;

    // Sleep hours (8 points) - optimal is 7-9 hours
    if (response.sleepHours >= 7 && response.sleepHours <= 9) {
      score += 8.0;
    } else if (response.sleepHours >= 6 && response.sleepHours <= 10) {
      score += 6.0;
    } else if (response.sleepHours >= 5) {
      score += 4.0;
    } else {
      score += 2.0;
    }

    // Sleep quality (4 points) - 1-5 scale
    score += (response.sleepQuality - 1) * 1.0; // Maps 1-5 to 0-4

    // Pain level (6 points) - inverse, 0-10 scale
    const painScore = 6.0 - response.painLevel * 0.6;
    score += Math.max(0, Math.min(6, painScore));

    // Energy level (7 points) - 1-5 scale
    score += (response.energyLevel - 1) * 1.75; // Maps 1-5 to 0-7

    return Math.max(0, Math.min(25, score));
  }

  /**
   * Calculate Mental Domain Score (25 points max)
   */
  private calculateMentalScore(response: QuestionnaireResponseDto): number {
    let score = 0;

    // Mood (10 points) - 1-5 scale
    score += (response.moodScore - 1) * 2.5; // Maps 1-5 to 0-10

    // Anxiety (8 points) - inverse, 1-5 scale
    score += (5 - response.anxietyLevel) * 2.0; // Maps 5-1 to 0-8

    // Stress (7 points) - inverse, 1-5 scale
    score += (5 - response.stressLevel) * 1.75; // Maps 5-1 to 0-7

    return Math.max(0, Math.min(25, score));
  }

  /**
   * Calculate Lifestyle Domain Score (25 points max)
   */
  private calculateLifestyleScore(response: QuestionnaireResponseDto): number {
    let score = 0;

    // Exercise (8 points) - 150+ min/week is optimal
    if (response.exerciseMinutesPerWeek >= 150) {
      score += 8.0;
    } else if (response.exerciseMinutesPerWeek >= 100) {
      score += 6.0;
    } else if (response.exerciseMinutesPerWeek >= 50) {
      score += 4.0;
    } else {
      score += 2.0;
    }

    // Diet quality (9 points) - 1-5 scale
    score += (response.dietQuality - 1) * 2.25; // Maps 1-5 to 0-9

    // Alcohol (8 points) - 0-14 drinks/week is moderate
    if (response.alcoholDrinksPerWeek === 0) {
      score += 8.0;
    } else if (response.alcoholDrinksPerWeek <= 7) {
      score += 6.0;
    } else if (response.alcoholDrinksPerWeek <= 14) {
      score += 4.0;
    } else {
      score += 2.0;
    }

    return Math.max(0, Math.min(25, score));
  }

  /**
   * Calculate Social Domain Score (25 points max)
   */
  private calculateSocialScore(response: QuestionnaireResponseDto): number {
    let score = 0;

    // Social connection (10 points) - 1-5 scale
    score += (response.socialConnection - 1) * 2.5;

    // Life satisfaction (10 points) - 1-5 scale
    score += (response.lifeSatisfaction - 1) * 2.5;

    // Work-life balance (5 points) - 1-5 scale
    score += (response.workLifeBalance - 1) * 1.25;

    return Math.max(0, Math.min(25, score));
  }

  /**
   * Get status label from total score
   */
  private getStatusFromScore(score: number): string {
    if (score >= 91) return 'RADIANT';
    if (score >= 76) return 'THRIVING';
    if (score >= 61) return 'BALANCED';
    if (score >= 41) return 'REBUILDING';
    return 'NEEDS_SUPPORT';
  }

  /**
   * Update score based on daily check-ins (weighted moving average)
   */
  updateScoreWithCheckin(
    currentScore: number,
    checkinData: {
      sleepQuality: number;
      energyLevel: number;
      mood: number;
      stressLevel: number;
    },
  ): number {
    // Convert check-in to a daily score (0-100)
    const dailyScore =
      (checkinData.sleepQuality - 1) * 6.25 + // 0-25
      (checkinData.energyLevel - 1) * 6.25 + // 0-25
      (checkinData.mood - 1) * 6.25 + // 0-25
      (5 - checkinData.stressLevel) * 6.25; // 0-25 (inverted)

    // Weighted average: 90% current, 10% new data (slow movement)
    const newScore = currentScore * 0.9 + dailyScore * 0.1;

    return Math.round(newScore);
  }
}
