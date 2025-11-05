import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { UserRole } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Register a new user with email and password
   */
  async signup(signupDto: SignupDto) {
    // Check if user already exists
    const existingUser = await this.prisma.user.findUnique({
      where: { email: signupDto.email },
    });

    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Hash password
    const bcryptRounds = this.configService.get<number>('BCRYPT_ROUNDS') || 10;
    const passwordHash = await bcrypt.hash(signupDto.password, bcryptRounds);

    // Create user
    const user = await this.prisma.user.create({
      data: {
        email: signupDto.email,
        passwordHash,
        name: signupDto.name,
        role: signupDto.role,
        profilePhoto: signupDto.profilePhoto,
        lastLoginAt: new Date(),
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        profilePhoto: true,
        createdAt: true,
      },
    });

    // Create profile based on role
    if (signupDto.role === UserRole.CLIENT) {
      await this.prisma.clientProfile.create({
        data: {
          userId: user.id,
        },
      });
    } else if (signupDto.role === UserRole.PRACTITIONER) {
      await this.prisma.practitionerProfile.create({
        data: {
          userId: user.id,
        },
      });
    }

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email, user.role);

    return {
      success: true,
      data: {
        user,
        ...tokens,
      },
    };
  }

  /**
   * Login with email and password
   */
  async login(loginDto: LoginDto) {
    // Find user
    const user = await this.prisma.user.findUnique({
      where: { email: loginDto.email },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        profilePhoto: true,
        passwordHash: true,
        createdAt: true,
      },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(loginDto.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Update last login
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    // Remove passwordHash from response
    const { passwordHash, ...userWithoutPassword } = user;

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email, user.role);

    return {
      success: true,
      data: {
        user: userWithoutPassword,
        ...tokens,
      },
    };
  }

  /**
   * Login or signup with Google OAuth
   */
  async googleAuth(googleAuthDto: GoogleAuthDto) {
    // Check if user exists with Google ID
    let user = await this.prisma.user.findUnique({
      where: { googleId: googleAuthDto.googleId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        profilePhoto: true,
        googleId: true,
        createdAt: true,
      },
    });

    // If not found by Google ID, check by email
    if (!user) {
      user = await this.prisma.user.findUnique({
        where: { email: googleAuthDto.email },
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          profilePhoto: true,
          googleId: true,
          createdAt: true,
        },
      });

      // If found by email but no Google ID, link accounts
      if (user && !user.googleId) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            googleId: googleAuthDto.googleId,
            profilePhoto: googleAuthDto.profilePhoto || user.profilePhoto,
            lastLoginAt: new Date(),
          },
          select: {
            id: true,
            email: true,
            name: true,
            role: true,
            profilePhoto: true,
            googleId: true,
            createdAt: true,
          },
        });
      }
    }

    // If user still doesn't exist, create new account
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          googleId: googleAuthDto.googleId,
          email: googleAuthDto.email,
          name: googleAuthDto.name,
          role: googleAuthDto.role,
          profilePhoto: googleAuthDto.profilePhoto,
          lastLoginAt: new Date(),
        },
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          profilePhoto: true,
          googleId: true,
          createdAt: true,
        },
      });

      // Create profile based on role
      if (googleAuthDto.role === UserRole.CLIENT) {
        await this.prisma.clientProfile.create({
          data: {
            userId: user.id,
          },
        });
      } else if (googleAuthDto.role === UserRole.PRACTITIONER) {
        await this.prisma.practitionerProfile.create({
          data: {
            userId: user.id,
          },
        });
      }
    } else {
      // Update last login
      await this.prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });
    }

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email, user.role);

    return {
      success: true,
      data: {
        user,
        ...tokens,
      },
    };
  }

  /**
   * Refresh access token using refresh token
   */
  async refreshTokens(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync(refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, email: true, role: true },
      });

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      const tokens = await this.generateTokens(user.id, user.email, user.role);

      return {
        success: true,
        data: tokens,
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  /**
   * Get current user from JWT payload
   */
  async getCurrentUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        profilePhoto: true,
        createdAt: true,
        clientProfile: {
          select: {
            id: true,
            questionnaireCompleted: true,
            currentScore: true,
            currentStatus: true,
            domainScores: true,
          },
        },
        practitionerProfile: {
          select: {
            id: true,
            practiceName: true,
            bio: true,
            postcode: true,
            phone: true,
            website: true,
            specialties: true,
            modalities: true,
            verificationStatus: true,
            verifiedBadges: true,
            sanaIndexScore: true,
          },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      success: true,
      data: user,
    };
  }

  /**
   * Generate JWT access and refresh tokens
   */
  private async generateTokens(userId: string, email: string, role: UserRole) {
    const payload = { sub: userId, email, role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_SECRET'),
        expiresIn: this.configService.get<string>('JWT_EXPIRES_IN') || '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') || '7d',
      }),
    ]);

    return {
      accessToken,
      refreshToken,
    };
  }
}
