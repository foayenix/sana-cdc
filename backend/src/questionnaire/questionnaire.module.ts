import { Module } from '@nestjs/common';
import { QuestionnaireService } from './questionnaire.service';
import { QuestionnaireController } from './questionnaire.controller';
import { HealthScoreCalculator } from './health-score.calculator';

@Module({
  controllers: [QuestionnaireController],
  providers: [QuestionnaireService, HealthScoreCalculator],
  exports: [QuestionnaireService, HealthScoreCalculator],
})
export class QuestionnaireModule {}
