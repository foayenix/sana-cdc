import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from '../src/payments/payments.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { NotificationsService } from '../src/notifications/notifications.service';
import { NotFoundException, BadRequestException } from '@nestjs/common';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let prismaService: PrismaService;

  const mockPrismaService = {
    appointment: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    payment: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    stripeAccount: {
      findUnique: jest.fn(),
    },
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      const config = {
        STRIPE_SECRET_KEY: 'sk_test_mock',
      };
      return config[key];
    }),
  };

  const mockNotificationsService = {
    sendNotification: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createPaymentIntent', () => {
    it('should throw NotFoundException if appointment not found', async () => {
      mockPrismaService.appointment.findUnique.mockResolvedValue(null);

      await expect(
        service.createPaymentIntent('user-id', 'appointment-id'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if user is not the client', async () => {
      mockPrismaService.appointment.findUnique.mockResolvedValue({
        id: 'appointment-id',
        clientId: 'different-user-id',
        status: 'SCHEDULED',
      });

      await expect(
        service.createPaymentIntent('user-id', 'appointment-id'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for invalid appointment status', async () => {
      mockPrismaService.appointment.findUnique.mockResolvedValue({
        id: 'appointment-id',
        clientId: 'user-id',
        status: 'COMPLETED',
        sessionType: { priceGBP: 5000 },
      });

      await expect(
        service.createPaymentIntent('user-id', 'appointment-id'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should return existing payment if already exists', async () => {
      mockPrismaService.appointment.findUnique.mockResolvedValue({
        id: 'appointment-id',
        clientId: 'user-id',
        status: 'SCHEDULED',
        sessionType: { priceGBP: 5000 },
        practitioner: {
          user: { name: 'Dr. Test' },
          stripeAccount: null,
        },
        client: { user: { name: 'Client' } },
      });

      mockPrismaService.payment.findFirst.mockResolvedValue({
        id: 'payment-id',
        stripePaymentIntentId: 'pi_existing',
        amount: 5000,
        status: 'PENDING',
      });

      const result = await service.createPaymentIntent('user-id', 'appointment-id');

      expect(result.clientSecret).toBe('pi_existing');
      expect(result.paymentId).toBe('payment-id');
    });

    it('should calculate 10% platform fee correctly', async () => {
      const appointmentPrice = 10000; // £100.00

      mockPrismaService.appointment.findUnique.mockResolvedValue({
        id: 'appointment-id',
        clientId: 'user-id',
        status: 'SCHEDULED',
        sessionType: { priceGBP: appointmentPrice, name: 'Consultation' },
        practitioner: {
          user: { name: 'Dr. Test' },
          stripeAccount: { stripeAccountId: 'acct_test', enabled: true },
        },
        client: { user: { name: 'Client' } },
        practitionerId: 'practitioner-id',
      });

      mockPrismaService.payment.findFirst.mockResolvedValue(null);
      mockPrismaService.payment.create.mockResolvedValue({
        id: 'payment-id',
        stripePaymentIntentId: 'pi_new',
        stripeClientSecret: 'pi_new_secret',
        amount: appointmentPrice,
        platformFee: 1000, // 10%
        stripeFee: 170, // 1.5% + 20p
        netAmount: 8830,
      });

      // Mock Stripe API call
      jest.spyOn(service['stripe'].paymentIntents, 'create').mockResolvedValue({
        id: 'pi_new',
        client_secret: 'pi_new_secret',
      } as any);

      const result = await service.createPaymentIntent('user-id', 'appointment-id');

      expect(result.platformFee).toBe(1000); // £10.00
      expect(result.netAmount).toBe(8830); // £88.30 (after platform fee and Stripe fee)
    });
  });

  describe('getPayment', () => {
    it('should throw NotFoundException if payment not found', async () => {
      mockPrismaService.payment.findUnique.mockResolvedValue(null);

      await expect(service.getPayment('payment-id', 'user-id')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw BadRequestException if user has no access', async () => {
      mockPrismaService.payment.findUnique.mockResolvedValue({
        id: 'payment-id',
        appointment: {
          clientId: 'different-user-id',
          practitionerId: 'another-user-id',
        },
      });

      await expect(service.getPayment('payment-id', 'user-id')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should return payment for client', async () => {
      const mockPayment = {
        id: 'payment-id',
        amount: 5000,
        appointment: {
          clientId: 'user-id',
          practitionerId: 'practitioner-id',
        },
      };

      mockPrismaService.payment.findUnique.mockResolvedValue(mockPayment);

      const result = await service.getPayment('payment-id', 'user-id');

      expect(result).toEqual(mockPayment);
    });

    it('should return payment for practitioner', async () => {
      const mockPayment = {
        id: 'payment-id',
        amount: 5000,
        appointment: {
          clientId: 'client-id',
          practitionerId: 'user-id',
        },
      };

      mockPrismaService.payment.findUnique.mockResolvedValue(mockPayment);

      const result = await service.getPayment('payment-id', 'user-id');

      expect(result).toEqual(mockPayment);
    });
  });

  describe('refundPayment', () => {
    it('should throw NotFoundException if payment not found', async () => {
      mockPrismaService.payment.findUnique.mockResolvedValue(null);

      await expect(
        service.refundPayment('payment-id', 'user-id', 'reason'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if not practitioner', async () => {
      mockPrismaService.payment.findUnique.mockResolvedValue({
        id: 'payment-id',
        appointment: {
          practitionerId: 'different-practitioner-id',
        },
      });

      await expect(
        service.refundPayment('payment-id', 'user-id', 'reason'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if payment not completed', async () => {
      mockPrismaService.payment.findUnique.mockResolvedValue({
        id: 'payment-id',
        status: 'PENDING',
        appointment: {
          practitionerId: 'user-id',
        },
      });

      await expect(
        service.refundPayment('payment-id', 'user-id', 'reason'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if appointment not cancelled', async () => {
      mockPrismaService.payment.findUnique.mockResolvedValue({
        id: 'payment-id',
        status: 'COMPLETED',
        appointment: {
          practitionerId: 'user-id',
          status: 'CONFIRMED',
        },
      });

      await expect(
        service.refundPayment('payment-id', 'user-id', 'reason'),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
