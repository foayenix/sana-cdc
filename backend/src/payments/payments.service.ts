import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import Stripe from 'stripe';

@Injectable()
export class PaymentsService {
  private readonly stripe: Stripe;
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    const stripeSecretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!stripeSecretKey) {
      this.logger.warn('STRIPE_SECRET_KEY not configured');
    }
    this.stripe = new Stripe(stripeSecretKey || '', {
      apiVersion: '2024-11-20.acacia',
    });
  }

  // Create payment intent for appointment
  async createPaymentIntent(userId: string, appointmentId: string) {
    // Get appointment details
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        sessionType: true,
        practitioner: {
          include: {
            user: true,
          },
        },
        client: {
          include: {
            user: true,
          },
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Verify user is the client
    if (appointment.clientId !== userId) {
      throw new BadRequestException('You can only pay for your own appointments');
    }

    // Check if appointment is in valid status for payment
    if (appointment.status !== 'SCHEDULED' && appointment.status !== 'CONFIRMED') {
      throw new BadRequestException(
        `Cannot create payment for appointment with status: ${appointment.status}`,
      );
    }

    // Check if payment already exists
    const existingPayment = await this.prisma.payment.findFirst({
      where: {
        appointmentId,
        status: {
          in: ['PENDING', 'COMPLETED'],
        },
      },
    });

    if (existingPayment) {
      // Return existing payment intent
      return {
        clientSecret: existingPayment.stripePaymentIntentId,
        paymentId: existingPayment.id,
        amount: existingPayment.amount,
      };
    }

    // Create Stripe payment intent
    const amount = Math.round(appointment.sessionType.priceGBP * 100); // Convert to pence
    const paymentIntent = await this.stripe.paymentIntents.create({
      amount,
      currency: 'gbp',
      metadata: {
        appointmentId: appointment.id,
        clientId: appointment.clientId,
        practitionerId: appointment.practitionerId,
        sessionTypeName: appointment.sessionType.name,
      },
      description: `Payment for ${appointment.sessionType.name} with ${appointment.practitioner.user.name}`,
    });

    // Create payment record
    const payment = await this.prisma.payment.create({
      data: {
        appointmentId,
        amount: appointment.sessionType.priceGBP,
        currency: 'GBP',
        status: 'PENDING',
        stripePaymentIntentId: paymentIntent.id,
        stripeClientSecret: paymentIntent.client_secret,
      },
    });

    this.logger.log(
      `Created payment intent ${paymentIntent.id} for appointment ${appointmentId}`,
    );

    return {
      clientSecret: paymentIntent.client_secret,
      paymentId: payment.id,
      amount: payment.amount,
    };
  }

  // Confirm payment (webhook or manual check)
  async confirmPayment(paymentIntentId: string) {
    // Get payment intent from Stripe
    const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentIntentId);

    // Find payment record
    const payment = await this.prisma.payment.findFirst({
      where: { stripePaymentIntentId: paymentIntentId },
      include: { appointment: true },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    // Update payment status based on Stripe status
    let newStatus: 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED' = 'PENDING';

    if (paymentIntent.status === 'succeeded') {
      newStatus = 'COMPLETED';
    } else if (paymentIntent.status === 'canceled' || paymentIntent.status === 'requires_payment_method') {
      newStatus = 'FAILED';
    }

    const updatedPayment = await this.prisma.payment.update({
      where: { id: payment.id },
      data: {
        status: newStatus,
        paidAt: newStatus === 'COMPLETED' ? new Date() : null,
      },
      include: {
        appointment: {
          include: {
            sessionType: true,
            client: {
              include: { user: true },
            },
            practitioner: {
              include: { user: true },
            },
          },
        },
      },
    });

    // If payment completed, update appointment status to CONFIRMED
    if (newStatus === 'COMPLETED' && payment.appointment.status === 'SCHEDULED') {
      await this.prisma.appointment.update({
        where: { id: payment.appointmentId },
        data: { status: 'CONFIRMED' },
      });
    }

    this.logger.log(
      `Payment ${payment.id} status updated to ${newStatus} for appointment ${payment.appointmentId}`,
    );

    return updatedPayment;
  }

  // Get payment by ID
  async getPayment(paymentId: string, userId: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        appointment: {
          include: {
            sessionType: true,
            client: {
              include: { user: true },
            },
            practitioner: {
              include: { user: true },
            },
          },
        },
      },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    // Verify user has access to this payment
    if (
      payment.appointment.clientId !== userId &&
      payment.appointment.practitionerId !== userId
    ) {
      throw new BadRequestException('Access denied');
    }

    return payment;
  }

  // Get all payments for user
  async getPayments(userId: string, role: 'CLIENT' | 'PRACTITIONER') {
    const payments = await this.prisma.payment.findMany({
      where: {
        appointment:
          role === 'CLIENT'
            ? { clientId: userId }
            : { practitionerId: userId },
      },
      include: {
        appointment: {
          include: {
            sessionType: true,
            client: {
              include: { user: true },
            },
            practitioner: {
              include: { user: true },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return payments;
  }

  // Process refund
  async refundPayment(paymentId: string, userId: string, reason?: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        appointment: {
          include: {
            client: true,
            practitioner: true,
          },
        },
      },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    // Only practitioner or admin can initiate refund
    if (payment.appointment.practitionerId !== userId) {
      throw new BadRequestException('Only practitioner can initiate refund');
    }

    if (payment.status !== 'COMPLETED') {
      throw new BadRequestException('Can only refund completed payments');
    }

    // Check if appointment is cancelled
    if (payment.appointment.status !== 'CANCELLED') {
      throw new BadRequestException('Appointment must be cancelled before refunding');
    }

    // Create refund in Stripe
    const refund = await this.stripe.refunds.create({
      payment_intent: payment.stripePaymentIntentId,
      reason: 'requested_by_customer',
      metadata: {
        appointmentId: payment.appointmentId,
        reason: reason || 'Appointment cancelled',
      },
    });

    // Update payment status
    const updatedPayment = await this.prisma.payment.update({
      where: { id: paymentId },
      data: {
        status: 'REFUNDED',
        refundedAt: new Date(),
      },
    });

    this.logger.log(
      `Refund processed for payment ${paymentId}, refund ID: ${refund.id}`,
    );

    return updatedPayment;
  }

  // Webhook handler for Stripe events
  async handleStripeWebhook(event: Stripe.Event) {
    this.logger.log(`Received Stripe webhook: ${event.type}`);

    switch (event.type) {
      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await this.confirmPayment(paymentIntent.id);
        break;

      case 'payment_intent.payment_failed':
        const failedIntent = event.data.object as Stripe.PaymentIntent;
        await this.handlePaymentFailed(failedIntent.id);
        break;

      case 'charge.refunded':
        const refundedCharge = event.data.object as Stripe.Charge;
        await this.handleRefund(refundedCharge.payment_intent as string);
        break;

      default:
        this.logger.log(`Unhandled event type: ${event.type}`);
    }

    return { received: true };
  }

  private async handlePaymentFailed(paymentIntentId: string) {
    const payment = await this.prisma.payment.findFirst({
      where: { stripePaymentIntentId: paymentIntentId },
    });

    if (payment) {
      await this.prisma.payment.update({
        where: { id: payment.id },
        data: { status: 'FAILED' },
      });

      this.logger.log(`Payment ${payment.id} marked as FAILED`);
    }
  }

  private async handleRefund(paymentIntentId: string) {
    const payment = await this.prisma.payment.findFirst({
      where: { stripePaymentIntentId: paymentIntentId },
    });

    if (payment && payment.status !== 'REFUNDED') {
      await this.prisma.payment.update({
        where: { id: payment.id },
        data: {
          status: 'REFUNDED',
          refundedAt: new Date(),
        },
      });

      this.logger.log(`Payment ${payment.id} marked as REFUNDED`);
    }
  }
}
