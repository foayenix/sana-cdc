import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { QuestionnaireService } from './questionnaire.service';
import { QuestionnaireResponseDto } from './dto/questionnaire-response.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('questionnaire')
@UseGuards(JwtAuthGuard)
export class QuestionnaireController {
  constructor(private readonly questionnaireService: QuestionnaireService) {}

  /**
   * POST /api/questionnaire
   * Submit health questionnaire
   */
  @Post()
  async submitQuestionnaire(
    @CurrentUser() user: any,
    @Body() questionnaireResponse: QuestionnaireResponseDto,
  ) {
    return this.questionnaireService.submitQuestionnaire(
      user.id,
      user.role,
      questionnaireResponse,
    );
  }

  /**
   * GET /api/questionnaire/score
   * Get current health score
   */
  @Get('score')
  async getHealthScore(@CurrentUser() user: any) {
    return this.questionnaireService.getHealthScore(user.id, user.role);
  }

  /**
   * GET /api/questionnaire/levers
   * Get top 3 wellness levers
   */
  @Get('levers')
  async getTopLevers(@CurrentUser() user: any) {
    return this.questionnaireService.getTopLevers(user.id, user.role);
  }
}
