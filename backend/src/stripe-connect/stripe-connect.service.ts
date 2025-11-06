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
export class StripeConnectService {
  private readonly stripe: Stripe;
  private readonly logger = new Logger(StripeConnectService.name);

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

  /**
   * Create a Stripe Connect account for a practitioner
   */
  async createConnectAccount(practitionerId: string, email: string, name: string) {
    // Check if account already exists
    const existingAccount = await this.prisma.stripeAccount.findUnique({
      where: { practitionerId },
    });

    if (existingAccount) {
      return {
        accountId: existingAccount.stripeAccountId,
        alreadyExists: true,
      };
    }

    // Create Stripe Connect account
    const account = await this.stripe.accounts.create({
      type: 'express',
      country: 'GB',
      email,
      business_type: 'individual',
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      metadata: {
        practitionerId,
        name,
      },
    });

    // Save to database
    const stripeAccount = await this.prisma.stripeAccount.create({
      data: {
        practitionerId,
        stripeAccountId: account.id,
        enabled: false,
      },
    });

    this.logger.log(`Created Stripe Connect account ${account.id} for practitioner ${practitionerId}`);

    return {
      accountId: account.id,
      alreadyExists: false,
    };
  }

  /**
   * Generate onboarding link for practitioner to complete Stripe Connect setup
   */
  async createAccountLink(practitionerId: string) {
    const stripeAccount = await this.prisma.stripeAccount.findUnique({
      where: { practitionerId },
    });

    if (!stripeAccount) {
      throw new NotFoundException('Stripe Connect account not found. Please create one first.');
    }

    const frontendUrl = this.configService.get<string>('FRONTEND_URL') || 'http://localhost:8080';

    const accountLink = await this.stripe.accountLinks.create({
      account: stripeAccount.stripeAccountId,
      refresh_url: `${frontendUrl}/practitioner/stripe-connect/refresh`,
      return_url: `${frontendUrl}/practitioner/stripe-connect/complete`,
      type: 'account_onboarding',
    });

    this.logger.log(`Created onboarding link for practitioner ${practitionerId}`);

    return {
      url: accountLink.url,
    };
  }

  /**
   * Check if Stripe Connect account is fully onboarded
   */
  async checkAccountStatus(practitionerId: string) {
    const stripeAccount = await this.prisma.stripeAccount.findUnique({
      where: { practitionerId },
    });

    if (!stripeAccount) {
      return {
        exists: false,
        enabled: false,
        chargesEnabled: false,
        payoutsEnabled: false,
      };
    }

    // Get account details from Stripe
    const account = await this.stripe.accounts.retrieve(stripeAccount.stripeAccountId);

    // Update database if status changed
    const isEnabled = account.charges_enabled && account.payouts_enabled;
    if (isEnabled !== stripeAccount.enabled) {
      await this.prisma.stripeAccount.update({
        where: { id: stripeAccount.id },
        data: { enabled: isEnabled },
      });
    }

    return {
      exists: true,
      enabled: isEnabled,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      detailsSubmitted: account.details_submitted,
      requiresAction: !account.details_submitted || !isEnabled,
    };
  }

  /**
   * Get Stripe dashboard login link for practitioner
   */
  async createLoginLink(practitionerId: string) {
    const stripeAccount = await this.prisma.stripeAccount.findUnique({
      where: { practitionerId },
    });

    if (!stripeAccount) {
      throw new NotFoundException('Stripe Connect account not found');
    }

    const loginLink = await this.stripe.accounts.createLoginLink(
      stripeAccount.stripeAccountId,
    );

    return {
      url: loginLink.url,
    };
  }

  /**
   * Get account balance
   */
  async getAccountBalance(practitionerId: string) {
    const stripeAccount = await this.prisma.stripeAccount.findUnique({
      where: { practitionerId },
    });

    if (!stripeAccount || !stripeAccount.enabled) {
      throw new BadRequestException('Stripe Connect account not enabled');
    }

    const balance = await this.stripe.balance.retrieve({
      stripeAccount: stripeAccount.stripeAccountId,
    });

    return {
      available: balance.available,
      pending: balance.pending,
    };
  }

  /**
   * Get payout history from Stripe
   */
  async getPayoutHistory(practitionerId: string, limit: number = 10) {
    const stripeAccount = await this.prisma.stripeAccount.findUnique({
      where: { practitionerId },
    });

    if (!stripeAccount || !stripeAccount.enabled) {
      throw new BadRequestException('Stripe Connect account not enabled');
    }

    const payouts = await this.stripe.payouts.list(
      { limit },
      { stripeAccount: stripeAccount.stripeAccountId },
    );

    return payouts.data.map((payout) => ({
      id: payout.id,
      amount: payout.amount,
      currency: payout.currency,
      status: payout.status,
      arrivalDate: new Date(payout.arrival_date * 1000),
      createdAt: new Date(payout.created * 1000),
    }));
  }

  /**
   * Delete/disconnect Stripe Connect account
   */
  async deleteAccount(practitionerId: string) {
    const stripeAccount = await this.prisma.stripeAccount.findUnique({
      where: { practitionerId },
    });

    if (!stripeAccount) {
      throw new NotFoundException('Stripe Connect account not found');
    }

    // Delete from Stripe
    await this.stripe.accounts.del(stripeAccount.stripeAccountId);

    // Delete from database
    await this.prisma.stripeAccount.delete({
      where: { id: stripeAccount.id },
    });

    this.logger.log(`Deleted Stripe Connect account for practitioner ${practitionerId}`);

    return {
      success: true,
      message: 'Stripe Connect account deleted successfully',
    };
  }
}
