import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Auth API (e2e)', () => {
  let app: INestApplication;
  let prismaService: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();

    // Apply global pipes
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    prismaService = app.get<PrismaService>(PrismaService);

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    // Clean up database before each test
    await prismaService.user.deleteMany({
      where: { email: { contains: 'test' } },
    });
  });

  describe('/api/auth/signup (POST)', () => {
    it('should create a new client user', () => {
      return request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'test-client@example.com',
          password: 'Password123!',
          name: 'Test Client',
          role: 'CLIENT',
        })
        .expect(201)
        .then((response) => {
          expect(response.body.success).toBe(true);
          expect(response.body.data.user.email).toBe('test-client@example.com');
          expect(response.body.data.accessToken).toBeDefined();
          expect(response.body.data.refreshToken).toBeDefined();
          expect(response.body.data.user.passwordHash).toBeUndefined();
        });
    });

    it('should create a new practitioner user', () => {
      return request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'test-practitioner@example.com',
          password: 'Password123!',
          name: 'Test Practitioner',
          role: 'PRACTITIONER',
        })
        .expect(201)
        .then((response) => {
          expect(response.body.success).toBe(true);
          expect(response.body.data.user.role).toBe('PRACTITIONER');
        });
    });

    it('should return 409 if user already exists', async () => {
      // Create user first
      await request(app.getHttpServer()).post('/api/auth/signup').send({
        email: 'test-duplicate@example.com',
        password: 'Password123!',
        name: 'Test User',
        role: 'CLIENT',
      });

      // Try to create again
      return request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'test-duplicate@example.com',
          password: 'Password123!',
          name: 'Test User',
          role: 'CLIENT',
        })
        .expect(409);
    });

    it('should return 400 for invalid email', () => {
      return request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'invalid-email',
          password: 'Password123!',
          name: 'Test User',
          role: 'CLIENT',
        })
        .expect(400);
    });

    it('should return 400 for weak password', () => {
      return request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'test@example.com',
          password: '123',
          name: 'Test User',
          role: 'CLIENT',
        })
        .expect(400);
    });

    it('should return 400 for missing required fields', () => {
      return request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'test@example.com',
        })
        .expect(400);
    });
  });

  describe('/api/auth/login (POST)', () => {
    beforeEach(async () => {
      // Create test user
      await request(app.getHttpServer()).post('/api/auth/signup').send({
        email: 'test-login@example.com',
        password: 'Password123!',
        name: 'Test User',
        role: 'CLIENT',
      });
    });

    it('should login with valid credentials', () => {
      return request(app.getHttpServer())
        .post('/api/auth/login')
        .send({
          email: 'test-login@example.com',
          password: 'Password123!',
        })
        .expect(200)
        .then((response) => {
          expect(response.body.success).toBe(true);
          expect(response.body.data.user.email).toBe('test-login@example.com');
          expect(response.body.data.accessToken).toBeDefined();
          expect(response.body.data.refreshToken).toBeDefined();
        });
    });

    it('should return 401 for invalid credentials', () => {
      return request(app.getHttpServer())
        .post('/api/auth/login')
        .send({
          email: 'test-login@example.com',
          password: 'WrongPassword',
        })
        .expect(401);
    });

    it('should return 401 for non-existent user', () => {
      return request(app.getHttpServer())
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'Password123!',
        })
        .expect(401);
    });
  });

  describe('/api/auth/me (GET)', () => {
    let accessToken: string;

    beforeEach(async () => {
      // Create and login user
      const response = await request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'test-me@example.com',
          password: 'Password123!',
          name: 'Test User',
          role: 'CLIENT',
        });

      accessToken = response.body.data.accessToken;
    });

    it('should return current user with valid token', () => {
      return request(app.getHttpServer())
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200)
        .then((response) => {
          expect(response.body.success).toBe(true);
          expect(response.body.data.email).toBe('test-me@example.com');
        });
    });

    it('should return 401 without token', () => {
      return request(app.getHttpServer()).get('/api/auth/me').expect(401);
    });

    it('should return 401 with invalid token', () => {
      return request(app.getHttpServer())
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });

  describe('/api/auth/refresh (POST)', () => {
    let refreshToken: string;

    beforeEach(async () => {
      // Create and login user
      const response = await request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({
          email: 'test-refresh@example.com',
          password: 'Password123!',
          name: 'Test User',
          role: 'CLIENT',
        });

      refreshToken = response.body.data.refreshToken;
    });

    it('should refresh tokens with valid refresh token', () => {
      return request(app.getHttpServer())
        .post('/api/auth/refresh')
        .send({ refreshToken })
        .expect(200)
        .then((response) => {
          expect(response.body.success).toBe(true);
          expect(response.body.data.accessToken).toBeDefined();
          expect(response.body.data.refreshToken).toBeDefined();
        });
    });

    it('should return 401 with invalid refresh token', () => {
      return request(app.getHttpServer())
        .post('/api/auth/refresh')
        .send({ refreshToken: 'invalid-token' })
        .expect(401);
    });
  });

  describe('Rate Limiting', () => {
    it('should rate limit after multiple requests', async () => {
      const requests = [];

      // Make 15 rapid requests (limit is 10 per 60s)
      for (let i = 0; i < 15; i++) {
        requests.push(
          request(app.getHttpServer())
            .post('/api/auth/login')
            .send({
              email: 'test@example.com',
              password: 'password',
            }),
        );
      }

      const responses = await Promise.all(requests);
      const rateLimitedResponses = responses.filter((r) => r.status === 429);

      expect(rateLimitedResponses.length).toBeGreaterThan(0);
    });
  });
});
