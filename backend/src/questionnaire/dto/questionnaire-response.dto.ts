import { IsNumber, Min, Max, IsArray, IsString } from 'class-validator';

export class QuestionnaireResponseDto {
  // Physical Domain
  @IsNumber()
  @Min(0)
  @Max(12)
  sleepHours: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  sleepQuality: number;

  @IsNumber()
  @Min(0)
  @Max(10)
  painLevel: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  energyLevel: number;

  // Mental Domain
  @IsNumber()
  @Min(1)
  @Max(5)
  moodScore: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  anxietyLevel: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  stressLevel: number;

  // Lifestyle Domain
  @IsNumber()
  @Min(0)
  @Max(1000)
  exerciseMinutesPerWeek: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  dietQuality: number;

  @IsNumber()
  @Min(0)
  @Max(50)
  alcoholDrinksPerWeek: number;

  // Social Domain
  @IsNumber()
  @Min(1)
  @Max(5)
  socialConnection: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  lifeSatisfaction: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  workLifeBalance: number;

  // Additional Context
  @IsArray()
  @IsString({ each: true })
  mainHealthConcerns: string[];

  @IsArray()
  @IsString({ each: true })
  practitionerTypesLooking: string[];
}
