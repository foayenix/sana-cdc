import { IsString, IsOptional } from 'class-validator';

export class DeleteAccountDto {
  @IsString()
  @IsOptional()
  reason?: string;

  @IsString()
  password: string; // Require password confirmation for security
}
