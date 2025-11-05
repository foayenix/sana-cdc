import { IsNumber, Min, Max } from 'class-validator';

export class CreateCheckinDto {
  @IsNumber()
  @Min(1)
  @Max(5)
  sleepQuality: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  energyLevel: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  mood: number;

  @IsNumber()
  @Min(1)
  @Max(5)
  stressLevel: number;
}
