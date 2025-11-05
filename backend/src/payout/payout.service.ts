import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PayoutStatus, PaymentStatus, Prisma } from '@prisma/client';

// DTOs
export interface CreatePayoutDto {
  practitionerId: string;
  periodStart: Date;
  periodEnd: Date;
  description?: string;
}

export interface GetPayoutsDto {
  practitionerId: string;
  status?: PayoutStatus;
  limit?: number;
  offset?: number;
}

export interface PayoutSummaryDto {
  totalPayouts: number;
  totalAmount: number;
  pendingAmount: number;
  completedAmount: number;
  nextPayoutDate?: Date;
  unpaidPaymentsCount: number;
  unpaidPaymentsAmount: number;
}

@Injectable()
export class PayoutService {
  constructor(private prisma: PrismaService) {}

  // Create a payout for a practitioner
  async createPayout(dto: CreatePayoutDto) {
    const { practitionerId, periodStart, periodEnd, description } = dto;

    // Get all completed payments for this practitioner in the period that haven't been paid out
    const payments = await this.prisma.payment.findMany({
      where: {
        practitionerId,
        status: PaymentStatus.COMPLETED,
        payoutId: null, // Not yet included in a payout
        completedAt: {
          gte: periodStart,
          lte: periodEnd,
        },
      },
    });

    if (payments.length === 0) {
      throw new BadRequestException('No unpaid payments found for this period');
    }

    // Calculate total amount and net amount
    const totalAmount = payments.reduce((sum, p) => sum + (p.netAmount || p.amount), 0);
    const paymentCount = payments.length;

    // Create payout
    const payout = await this.prisma.payout.create({
      data: {
        practitionerId,
        amount: totalAmount,
        periodStart,
        periodEnd,
        description: description || `Payout for ${periodStart.toISOString().split('T')[0]} to ${periodEnd.toISOString().split('T')[0]}`,
        paymentCount,
        status: PayoutStatus.PENDING,
      },
      include: {
        practitioner: {
          select: {
            id: true,
            userId: true,
            practiceName: true,
            user: {
              select: { id: true, name: true, email: true },
            },
          },
        },
      },
    });

    // Link payments to this payout
    await this.prisma.payment.updateMany({
      where: {
        id: { in: payments.map((p) => p.id) },
      },
      data: {
        payoutId: payout.id,
      },
    });

    return payout;
  }

  // Get payout by ID
  async getPayoutById(payoutId: string) {
    const payout = await this.prisma.payout.findUnique({
      where: { id: payoutId },
      include: {
        practitioner: {
          select: {
            id: true,
            userId: true,
            practiceName: true,
            user: {
              select: { id: true, name: true, email: true },
            },
          },
        },
        payments: {
          include: {
            client: {
              select: { id: true, name: true, email: true },
            },
          },
        },
      },
    });

    if (!payout) {
      throw new NotFoundException('Payout not found');
    }

    return payout;
  }

  // Get payouts for a practitioner
  async getPayouts(dto: GetPayoutsDto) {
    const { practitionerId, status, limit = 50, offset = 0 } = dto;

    const where: Prisma.PayoutWhereInput = {
      practitionerId,
    };

    if (status) {
      where.status = status;
    }

    const [payouts, total] = await Promise.all([
      this.prisma.payout.findMany({
        where,
        include: {
          practitioner: {
            select: {
              id: true,
              userId: true,
              practiceName: true,
              user: {
                select: { id: true, name: true, email: true },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.payout.count({ where }),
    ]);

    return { payouts, total };
  }

  // Get payout summary for a practitioner
  async getPayoutSummary(practitionerId: string): Promise<PayoutSummaryDto> {
    const [
      totalPayouts,
      payouts,
      pendingPayout,
      completedPayout,
      unpaidPayments,
    ] = await Promise.all([
      this.prisma.payout.count({ where: { practitionerId } }),
      this.prisma.payout.findMany({
        where: { practitionerId },
        select: { amount: true },
      }),
      this.prisma.payout.findMany({
        where: { practitionerId, status: PayoutStatus.PENDING },
        select: { amount: true },
      }),
      this.prisma.payout.findMany({
        where: { practitionerId, status: PayoutStatus.COMPLETED },
        select: { amount: true },
      }),
      this.prisma.payment.findMany({
        where: {
          practitionerId,
          status: PaymentStatus.COMPLETED,
          payoutId: null,
        },
        select: { netAmount: true, amount: true },
      }),
    ]);

    const totalAmount = payouts.reduce((sum, p) => sum + p.amount, 0);
    const pendingAmount = pendingPayout.reduce((sum, p) => sum + p.amount, 0);
    const completedAmount = completedPayout.reduce((sum, p) => sum + p.amount, 0);
    const unpaidPaymentsAmount = unpaidPayments.reduce(
      (sum, p) => sum + (p.netAmount || p.amount),
      0,
    );

    // Calculate next payout date (e.g., first of next month)
    const nextPayoutDate = new Date();
    nextPayoutDate.setMonth(nextPayoutDate.getMonth() + 1);
    nextPayoutDate.setDate(1);

    return {
      totalPayouts,
      totalAmount,
      pendingAmount,
      completedAmount,
      nextPayoutDate,
      unpaidPaymentsCount: unpaidPayments.length,
      unpaidPaymentsAmount,
    };
  }

  // Update payout status
  async updatePayoutStatus(
    payoutId: string,
    status: PayoutStatus,
    stripePayoutId?: string,
    failureReason?: string,
  ) {
    const payout = await this.prisma.payout.update({
      where: { id: payoutId },
      data: {
        status,
        stripePayoutId,
        failureReason,
        completedAt: status === PayoutStatus.COMPLETED ? new Date() : null,
      },
      include: {
        practitioner: {
          select: {
            id: true,
            userId: true,
            practiceName: true,
            user: {
              select: { id: true, name: true, email: true },
            },
          },
        },
        payments: true,
      },
    });

    return payout;
  }

  // Get unpaid payments for a practitioner
  async getUnpaidPayments(practitionerId: string, limit = 50, offset = 0) {
    const [payments, total] = await Promise.all([
      this.prisma.payment.findMany({
        where: {
          practitionerId,
          status: PaymentStatus.COMPLETED,
          payoutId: null,
        },
        include: {
          client: {
            select: { id: true, name: true, email: true },
          },
        },
        orderBy: { completedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.payment.count({
        where: {
          practitionerId,
          status: PaymentStatus.COMPLETED,
          payoutId: null,
        },
      }),
    ]);

    return { payments, total };
  }

  // Get payout statistics (for charts/analytics)
  async getPayoutStatistics(
    practitionerId: string,
    period: 'week' | 'month' | 'year' = 'month',
  ) {
    const where: Prisma.PayoutWhereInput = {
      practitionerId,
      status: PayoutStatus.COMPLETED,
    };

    // Calculate date range based on period
    const now = new Date();
    const startDate = new Date();

    switch (period) {
      case 'week':
        startDate.setDate(now.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(now.getMonth() - 1);
        break;
      case 'year':
        startDate.setFullYear(now.getFullYear() - 1);
        break;
    }

    where.completedAt = { gte: startDate };

    const payouts = await this.prisma.payout.findMany({
      where,
      select: {
        amount: true,
        completedAt: true,
        paymentCount: true,
      },
      orderBy: { completedAt: 'asc' },
    });

    // Group by date
    const grouped = payouts.reduce((acc, payout) => {
      if (!payout.completedAt) return acc;
      const date = payout.completedAt.toISOString().split('T')[0];
      if (!acc[date]) {
        acc[date] = { date, amount: 0, count: 0, paymentCount: 0 };
      }
      acc[date].amount += payout.amount;
      acc[date].count += 1;
      acc[date].paymentCount += payout.paymentCount;
      return acc;
    }, {} as Record<string, { date: string; amount: number; count: number; paymentCount: number }>);

    return Object.values(grouped);
  }

  // Schedule payout
  async schedulePayout(payoutId: string, scheduledFor: Date) {
    const payout = await this.prisma.payout.update({
      where: { id: payoutId },
      data: {
        scheduledFor,
        status: PayoutStatus.PROCESSING,
      },
      include: {
        practitioner: {
          select: {
            id: true,
            userId: true,
            practiceName: true,
            user: {
              select: { id: true, name: true, email: true },
            },
          },
        },
      },
    });

    return payout;
  }
}
