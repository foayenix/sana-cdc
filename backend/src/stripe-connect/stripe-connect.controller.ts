import {
  Controller,
  Get,
  Post,
  Delete,
  UseGuards,
  Request,
} from '@nestjs/common';
import { StripeConnectService } from './stripe-connect.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Controller('stripe-connect')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.PRACTITIONER)
export class StripeConnectController {
  constructor(
    private readonly stripeConnectService: StripeConnectService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * POST /api/stripe-connect/account
   * Create a Stripe Connect account for the practitioner
   */
  @Post('account')
  async createAccount(@Request() req) {
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { practitionerProfile: true },
    });

    return this.stripeConnectService.createConnectAccount(
      user.practitionerProfile.id,
      user.email,
      user.name,
    );
  }

  /**
   * POST /api/stripe-connect/onboarding-link
   * Generate onboarding link for practitioner
   */
  @Post('onboarding-link')
  async createOnboardingLink(@Request() req) {
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { practitionerProfile: true },
    });

    return this.stripeConnectService.createAccountLink(user.practitionerProfile.id);
  }

  /**
   * GET /api/stripe-connect/status
   * Check Stripe Connect account status
   */
  @Get('status')
  async getAccountStatus(@Request() req) {
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { practitionerProfile: true },
    });

    return this.stripeConnectService.checkAccountStatus(user.practitionerProfile.id);
  }

  /**
   * POST /api/stripe-connect/dashboard-link
   * Get Stripe dashboard login link
   */
  @Post('dashboard-link')
  async getDashboardLink(@Request() req) {
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { practitionerProfile: true },
    });

    return this.stripeConnectService.createLoginLink(user.practitionerProfile.id);
  }

  /**
   * GET /api/stripe-connect/balance
   * Get account balance
   */
  @Get('balance')
  async getBalance(@Request() req) {
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { practitionerProfile: true },
    });

    return this.stripeConnectService.getAccountBalance(user.practitionerProfile.id);
  }

  /**
   * GET /api/stripe-connect/payouts
   * Get payout history
   */
  @Get('payouts')
  async getPayouts(@Request() req) {
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { practitionerProfile: true },
    });

    return this.stripeConnectService.getPayoutHistory(user.practitionerProfile.id);
  }

  /**
   * DELETE /api/stripe-connect/account
   * Delete Stripe Connect account
   */
  @Delete('account')
  async deleteAccount(@Request() req) {
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.userId },
      include: { practitionerProfile: true },
    });

    return this.stripeConnectService.deleteAccount(user.practitionerProfile.id);
  }
}
