import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RecommendationsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get all recommendation templates
   */
  async getAllRecommendations(category?: string) {
    const where = category ? { category } : {};

    const recommendations = await this.prisma.recommendationTemplate.findMany({
      where,
      orderBy: {
        title: 'asc',
      },
      select: {
        id: true,
        slug: true,
        title: true,
        category: true,
        createdAt: true,
      },
    });

    return {
      success: true,
      data: recommendations,
    };
  }

  /**
   * Get recommendation by slug
   */
  async getRecommendationBySlug(slug: string) {
    const recommendation = await this.prisma.recommendationTemplate.findUnique({
      where: { slug },
    });

    if (!recommendation) {
      throw new NotFoundException('Recommendation not found');
    }

    return {
      success: true,
      data: recommendation,
    };
  }

  /**
   * Get personalized recommendations based on domain scores
   */
  async getPersonalizedRecommendations(userId: string) {
    const clientProfile = await this.prisma.clientProfile.findUnique({
      where: { userId },
      select: {
        domainScores: true,
        questionnaireCompleted: true,
      },
    });

    if (!clientProfile || !clientProfile.questionnaireCompleted) {
      // Return general recommendations if no questionnaire completed
      return this.getAllRecommendations();
    }

    const domainScores = clientProfile.domainScores as any;

    // Identify lowest scoring domain
    const domains = [
      { name: 'physical', score: domainScores.physical, categories: ['Sleep', 'Pain', 'Energy'] },
      { name: 'mental', score: domainScores.mental, categories: ['Stress', 'Anxiety', 'Mood'] },
      {
        name: 'lifestyle',
        score: domainScores.lifestyle,
        categories: ['Exercise', 'Nutrition', 'Digestion'],
      },
      {
        name: 'social',
        score: domainScores.social,
        categories: ['Relationships', 'Work-Life Balance'],
      },
    ];

    const lowestDomain = domains.sort((a, b) => a.score - b.score)[0];

    // Get recommendations for the lowest scoring domain's categories
    const recommendations = await this.prisma.recommendationTemplate.findMany({
      where: {
        category: {
          in: lowestDomain.categories,
        },
      },
      take: 6,
      orderBy: {
        title: 'asc',
      },
    });

    return {
      success: true,
      data: recommendations,
      meta: {
        focusArea: lowestDomain.name,
        score: lowestDomain.score,
      },
    };
  }

  /**
   * Get available categories
   */
  async getCategories() {
    const categories = await this.prisma.recommendationTemplate.groupBy({
      by: ['category'],
      _count: {
        category: true,
      },
    });

    return {
      success: true,
      data: categories.map((c) => ({
        name: c.category,
        count: c._count.category,
      })),
    };
  }
}
