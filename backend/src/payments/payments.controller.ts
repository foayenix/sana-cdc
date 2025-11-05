import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  Headers,
  RawBodyRequest,
  Req,
  BadRequestException,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

@Controller('payments')
export class PaymentsController {
  private readonly stripe: Stripe;

  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly configService: ConfigService,
  ) {
    const stripeSecretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    this.stripe = new Stripe(stripeSecretKey || '', {
      apiVersion: '2024-11-20.acacia',
    });
  }

  // Create payment intent for appointment
  @Post('create-intent')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.CLIENT)
  async createPaymentIntent(
    @Request() req,
    @Body() createDto: { appointmentId: string },
  ) {
    return this.paymentsService.createPaymentIntent(
      req.user.userId,
      createDto.appointmentId,
    );
  }

  // Get all payments for authenticated user
  @Get()
  @UseGuards(JwtAuthGuard)
  async getPayments(@Request() req) {
    return this.paymentsService.getPayments(req.user.userId, req.user.role);
  }

  // Get payment by ID
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getPayment(@Request() req, @Param('id') paymentId: string) {
    return this.paymentsService.getPayment(paymentId, req.user.userId);
  }

  // Process refund (practitioner only)
  @Post(':id/refund')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async refundPayment(
    @Request() req,
    @Param('id') paymentId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.paymentsService.refundPayment(
      paymentId,
      req.user.userId,
      body?.reason,
    );
  }

  // Stripe webhook endpoint (public, no auth)
  @Post('webhook')
  async handleStripeWebhook(
    @Headers('stripe-signature') signature: string,
    @Req() request: RawBodyRequest<Request>,
  ) {
    if (!signature) {
      throw new BadRequestException('Missing stripe-signature header');
    }

    const webhookSecret = this.configService.get<string>(
      'STRIPE_WEBHOOK_SECRET',
    );

    if (!webhookSecret) {
      throw new BadRequestException('Webhook secret not configured');
    }

    let event: Stripe.Event;

    try {
      // Verify webhook signature
      event = this.stripe.webhooks.constructEvent(
        request.rawBody || request.body,
        signature,
        webhookSecret,
      );
    } catch (err) {
      throw new BadRequestException(`Webhook signature verification failed: ${err.message}`);
    }

    // Handle the event
    return this.paymentsService.handleStripeWebhook(event);
  }
}
