import { IsString, IsEmail, IsEnum, IsOptional } from 'class-validator';
import { UserRole } from '@prisma/client';

export class GoogleAuthDto {
  @IsString()
  googleId: string;

  @IsEmail()
  email: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  profilePhoto?: string;

  @IsEnum(UserRole)
  role: UserRole;
}
