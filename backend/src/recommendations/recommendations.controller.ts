import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { RecommendationsService } from './recommendations.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('recommendations')
export class RecommendationsController {
  constructor(private readonly recommendationsService: RecommendationsService) {}

  /**
   * GET /api/recommendations
   * List all recommendation templates (with optional category filter)
   */
  @Get()
  async getAllRecommendations(@Query('category') category?: string) {
    return this.recommendationsService.getAllRecommendations(category);
  }

  /**
   * GET /api/recommendations/categories
   * Get available categories
   */
  @Get('categories')
  async getCategories() {
    return this.recommendationsService.getCategories();
  }

  /**
   * GET /api/recommendations/personalized
   * Get personalized recommendations based on user's health score
   */
  @Get('personalized')
  @UseGuards(JwtAuthGuard)
  async getPersonalized(@CurrentUser() user: any) {
    return this.recommendationsService.getPersonalizedRecommendations(user.id);
  }

  /**
   * GET /api/recommendations/:slug
   * Get specific recommendation by slug
   */
  @Get(':slug')
  async getRecommendationBySlug(@Param('slug') slug: string) {
    return this.recommendationsService.getRecommendationBySlug(slug);
  }
}
