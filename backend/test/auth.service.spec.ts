import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from '../src/auth/auth.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException, ConflictException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

describe('AuthService', () => {
  let service: AuthService;
  let prismaService: PrismaService;
  let jwtService: JwtService;

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    clientProfile: {
      create: jest.fn(),
    },
    practitionerProfile: {
      create: jest.fn(),
    },
  };

  const mockJwtService = {
    signAsync: jest.fn(),
    verifyAsync: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      const config = {
        BCRYPT_ROUNDS: 10,
        JWT_SECRET: 'test-secret',
        JWT_EXPIRES_IN: '15m',
        JWT_REFRESH_SECRET: 'test-refresh-secret',
        JWT_REFRESH_EXPIRES_IN: '7d',
      };
      return config[key];
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    prismaService = module.get<PrismaService>(PrismaService);
    jwtService = module.get<JwtService>(JwtService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('signup', () => {
    it('should create a new user successfully', async () => {
      const signupDto = {
        email: 'test@example.com',
        password: 'Password123!',
        name: 'Test User',
        role: 'CLIENT' as any,
      };

      mockPrismaService.user.findUnique.mockResolvedValue(null);
      mockPrismaService.user.create.mockResolvedValue({
        id: 'user-id',
        email: signupDto.email,
        name: signupDto.name,
        role: signupDto.role,
        createdAt: new Date(),
      });
      mockPrismaService.clientProfile.create.mockResolvedValue({});
      mockJwtService.signAsync.mockResolvedValue('mock-token');

      const result = await service.signup(signupDto);

      expect(result.success).toBe(true);
      expect(result.data.user.email).toBe(signupDto.email);
      expect(result.data.accessToken).toBe('mock-token');
      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { email: signupDto.email },
      });
    });

    it('should throw ConflictException if user already exists', async () => {
      const signupDto = {
        email: 'existing@example.com',
        password: 'Password123!',
        name: 'Test User',
        role: 'CLIENT' as any,
      };

      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'existing-user-id',
        email: signupDto.email,
      });

      await expect(service.signup(signupDto)).rejects.toThrow(ConflictException);
    });

    it('should hash password with bcrypt', async () => {
      const signupDto = {
        email: 'test@example.com',
        password: 'Password123!',
        name: 'Test User',
        role: 'CLIENT' as any,
      };

      mockPrismaService.user.findUnique.mockResolvedValue(null);
      mockPrismaService.user.create.mockResolvedValue({
        id: 'user-id',
        email: signupDto.email,
        name: signupDto.name,
        role: signupDto.role,
      });
      mockPrismaService.clientProfile.create.mockResolvedValue({});
      mockJwtService.signAsync.mockResolvedValue('mock-token');

      const bcryptHashSpy = jest.spyOn(bcrypt, 'hash');

      await service.signup(signupDto);

      expect(bcryptHashSpy).toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('should login user with valid credentials', async () => {
      const loginDto = {
        email: 'test@example.com',
        password: 'Password123!',
      };

      const hashedPassword = await bcrypt.hash(loginDto.password, 10);

      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'user-id',
        email: loginDto.email,
        passwordHash: hashedPassword,
        name: 'Test User',
        role: 'CLIENT',
      });
      mockPrismaService.user.update.mockResolvedValue({});
      mockJwtService.signAsync.mockResolvedValue('mock-token');

      const result = await service.login(loginDto);

      expect(result.success).toBe(true);
      expect(result.data.user.email).toBe(loginDto.email);
      expect(result.data.accessToken).toBe('mock-token');
    });

    it('should throw UnauthorizedException with invalid credentials', async () => {
      const loginDto = {
        email: 'test@example.com',
        password: 'WrongPassword',
      };

      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException with incorrect password', async () => {
      const loginDto = {
        email: 'test@example.com',
        password: 'WrongPassword',
      };

      const hashedPassword = await bcrypt.hash('CorrectPassword', 10);

      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'user-id',
        email: loginDto.email,
        passwordHash: hashedPassword,
        name: 'Test User',
        role: 'CLIENT',
      });

      await expect(service.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('googleAuth', () => {
    it('should create new user for first-time Google login', async () => {
      const googleAuthDto = {
        googleId: 'google-id-123',
        email: 'test@gmail.com',
        name: 'Test User',
        role: 'CLIENT' as any,
        profilePhoto: 'https://example.com/photo.jpg',
      };

      mockPrismaService.user.findUnique.mockResolvedValue(null);
      mockPrismaService.user.create.mockResolvedValue({
        id: 'user-id',
        email: googleAuthDto.email,
        googleId: googleAuthDto.googleId,
        name: googleAuthDto.name,
        role: googleAuthDto.role,
      });
      mockPrismaService.clientProfile.create.mockResolvedValue({});
      mockJwtService.signAsync.mockResolvedValue('mock-token');

      const result = await service.googleAuth(googleAuthDto);

      expect(result.success).toBe(true);
      expect(result.data.user.googleId).toBe(googleAuthDto.googleId);
    });

    it('should login existing Google user', async () => {
      const googleAuthDto = {
        googleId: 'google-id-123',
        email: 'test@gmail.com',
        name: 'Test User',
        role: 'CLIENT' as any,
      };

      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'user-id',
        email: googleAuthDto.email,
        googleId: googleAuthDto.googleId,
        name: googleAuthDto.name,
        role: googleAuthDto.role,
      });
      mockPrismaService.user.update.mockResolvedValue({});
      mockJwtService.signAsync.mockResolvedValue('mock-token');

      const result = await service.googleAuth(googleAuthDto);

      expect(result.success).toBe(true);
    });
  });

  describe('refreshTokens', () => {
    it('should refresh tokens with valid refresh token', async () => {
      const refreshToken = 'valid-refresh-token';
      const payload = { sub: 'user-id', email: 'test@example.com', role: 'CLIENT' };

      mockJwtService.verifyAsync.mockResolvedValue(payload);
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: payload.sub,
        email: payload.email,
        role: payload.role,
      });
      mockJwtService.signAsync.mockResolvedValue('new-token');

      const result = await service.refreshTokens(refreshToken);

      expect(result.success).toBe(true);
      expect(result.data.accessToken).toBe('new-token');
    });

    it('should throw UnauthorizedException with invalid refresh token', async () => {
      const refreshToken = 'invalid-refresh-token';

      mockJwtService.verifyAsync.mockRejectedValue(new Error('Invalid token'));

      await expect(service.refreshTokens(refreshToken)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });
});
