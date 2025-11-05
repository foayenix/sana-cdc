import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentStatus, InvoiceStatus, Prisma } from '@prisma/client';

// DTOs
export interface GetPaymentsDto {
  userId: string;
  userRole: 'CLIENT' | 'PRACTITIONER';
  status?: PaymentStatus;
  startDate?: Date;
  endDate?: Date;
  minAmount?: number;
  maxAmount?: number;
  limit?: number;
  offset?: number;
}

export interface PaymentSummaryDto {
  totalPayments: number;
  totalAmount: number;
  totalRefunded: number;
  completedCount: number;
  pendingCount: number;
  failedCount: number;
}

export interface GenerateInvoiceDto {
  paymentId: string;
  dueDate: Date;
  taxRate?: number; // e.g., 0.20 for 20% VAT
  notes?: string;
}

@Injectable()
export class PaymentHistoryService {
  constructor(private prisma: PrismaService) {}

  // Get payment history with filters
  async getPayments(dto: GetPaymentsDto) {
    const {
      userId,
      userRole,
      status,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      limit = 50,
      offset = 0,
    } = dto;

    const where: Prisma.PaymentWhereInput = {};

    // Filter by user role
    if (userRole === 'CLIENT') {
      where.clientId = userId;
    } else if (userRole === 'PRACTITIONER') {
      where.practitionerId = userId;
    }

    // Filter by status
    if (status) {
      where.status = status;
    }

    // Filter by date range
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = startDate;
      if (endDate) where.createdAt.lte = endDate;
    }

    // Filter by amount range
    if (minAmount !== undefined || maxAmount !== undefined) {
      where.amount = {};
      if (minAmount !== undefined) where.amount.gte = minAmount;
      if (maxAmount !== undefined) where.amount.lte = maxAmount;
    }

    const [payments, total] = await Promise.all([
      this.prisma.payment.findMany({
        where,
        include: {
          client: {
            select: { id: true, name: true, email: true },
          },
          practitioner: {
            select: {
              id: true,
              name: true,
              email: true,
              practitionerProfile: {
                select: { practiceName: true },
              },
            },
          },
          invoice: true,
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.payment.count({ where }),
    ]);

    return { payments, total };
  }

  // Get payment by ID
  async getPaymentById(paymentId: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        client: {
          select: { id: true, name: true, email: true },
        },
        practitioner: {
          select: {
            id: true,
            name: true,
            email: true,
            practitionerProfile: {
              select: { practiceName: true },
            },
          },
        },
        invoice: true,
        payout: true,
      },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    return payment;
  }

  // Get payment summary for a user
  async getPaymentSummary(
    userId: string,
    userRole: 'CLIENT' | 'PRACTITIONER',
  ): Promise<PaymentSummaryDto> {
    const where: Prisma.PaymentWhereInput = {};

    if (userRole === 'CLIENT') {
      where.clientId = userId;
    } else if (userRole === 'PRACTITIONER') {
      where.practitionerId = userId;
    }

    const [
      totalPayments,
      payments,
      completedCount,
      pendingCount,
      failedCount,
    ] = await Promise.all([
      this.prisma.payment.count({ where }),
      this.prisma.payment.findMany({
        where,
        select: { amount: true, refundedAmount: true },
      }),
      this.prisma.payment.count({
        where: { ...where, status: PaymentStatus.COMPLETED },
      }),
      this.prisma.payment.count({
        where: { ...where, status: PaymentStatus.PENDING },
      }),
      this.prisma.payment.count({
        where: { ...where, status: PaymentStatus.FAILED },
      }),
    ]);

    const totalAmount = payments.reduce((sum, p) => sum + p.amount, 0);
    const totalRefunded = payments.reduce(
      (sum, p) => sum + (p.refundedAmount || 0),
      0,
    );

    return {
      totalPayments,
      totalAmount,
      totalRefunded,
      completedCount,
      pendingCount,
      failedCount,
    };
  }

  // Generate invoice for a payment
  async generateInvoice(dto: GenerateInvoiceDto) {
    const { paymentId, dueDate, taxRate = 0, notes } = dto;

    // Get payment
    const payment = await this.getPaymentById(paymentId);

    // Check if invoice already exists
    if (payment.invoice) {
      throw new Error('Invoice already exists for this payment');
    }

    // Calculate amounts
    const subtotal = payment.amount;
    const taxAmount = Math.round(subtotal * taxRate);
    const total = subtotal + taxAmount;

    // Generate invoice number
    const year = new Date().getFullYear();
    const count = await this.prisma.invoice.count();
    const paddedCount = String(count + 1).padStart(6, '0');
    const invoiceNumber = 'INV-' + year + '-' + paddedCount;

    // Create invoice
    const invoice = await this.prisma.invoice.create({
      data: {
        paymentId,
        clientId: payment.clientId,
        practitionerId: payment.practitionerId,
        invoiceNumber,
        status: InvoiceStatus.SENT,
        subtotal,
        taxAmount,
        total,
        dueDate,
        notes,
        paidDate: payment.status === PaymentStatus.COMPLETED ? new Date() : null,
      },
      include: {
        payment: true,
        client: {
          select: { id: true, name: true, email: true },
        },
        practitioner: {
          select: {
            id: true,
            name: true,
            email: true,
            practitionerProfile: {
              select: { practiceName: true },
            },
          },
        },
      },
    });

    return invoice;
  }

  // Get invoice by ID
  async getInvoiceById(invoiceId: string) {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: {
        payment: true,
        client: {
          select: { id: true, name: true, email: true },
        },
        practitioner: {
          select: {
            id: true,
            name: true,
            email: true,
            practitionerProfile: {
              select: { practiceName: true },
            },
          },
        },
      },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    return invoice;
  }

  // Get invoices for a user
  async getInvoices(
    userId: string,
    userRole: 'CLIENT' | 'PRACTITIONER',
    limit = 50,
    offset = 0,
  ) {
    const where: Prisma.InvoiceWhereInput = {};

    if (userRole === 'CLIENT') {
      where.clientId = userId;
    } else if (userRole === 'PRACTITIONER') {
      where.practitionerId = userId;
    }

    const [invoices, total] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        include: {
          payment: true,
          client: {
            select: { id: true, name: true, email: true },
          },
          practitioner: {
            select: {
              id: true,
              name: true,
              email: true,
              practitionerProfile: {
                select: { practiceName: true },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.invoice.count({ where }),
    ]);

    return { invoices, total };
  }

  // Update invoice status
  async updateInvoiceStatus(invoiceId: string, status: InvoiceStatus) {
    const invoice = await this.prisma.invoice.update({
      where: { id: invoiceId },
      data: {
        status,
        paidDate: status === InvoiceStatus.PAID ? new Date() : null,
      },
      include: {
        payment: true,
        client: {
          select: { id: true, name: true, email: true },
        },
        practitioner: {
          select: {
            id: true,
            name: true,
            email: true,
            practitionerProfile: {
              select: { practiceName: true },
            },
          },
        },
      },
    });

    return invoice;
  }

  // Get payment statistics (for charts/analytics)
  async getPaymentStatistics(
    userId: string,
    userRole: 'CLIENT' | 'PRACTITIONER',
    period: 'week' | 'month' | 'year' = 'month',
  ) {
    const where: Prisma.PaymentWhereInput = {
      status: PaymentStatus.COMPLETED,
    };

    if (userRole === 'CLIENT') {
      where.clientId = userId;
    } else if (userRole === 'PRACTITIONER') {
      where.practitionerId = userId;
    }

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

    where.createdAt = { gte: startDate };

    const payments = await this.prisma.payment.findMany({
      where,
      select: {
        amount: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'asc' },
    });

    // Group by date
    const grouped = payments.reduce((acc, payment) => {
      const date = payment.createdAt.toISOString().split('T')[0];
      if (!acc[date]) {
        acc[date] = { date, amount: 0, count: 0 };
      }
      acc[date].amount += payment.amount;
      acc[date].count += 1;
      return acc;
    }, {} as Record<string, { date: string; amount: number; count: number }>);

    return Object.values(grouped);
  }
}
