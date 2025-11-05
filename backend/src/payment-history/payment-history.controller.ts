import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  Request,
} from '@nestjs/common';
import {
  PaymentHistoryService,
  GetPaymentsDto,
  GenerateInvoiceDto,
} from './payment-history.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PaymentStatus } from '@prisma/client';

@Controller('payment-history')
@UseGuards(JwtAuthGuard)
export class PaymentHistoryController {
  constructor(
    private readonly paymentHistoryService: PaymentHistoryService,
  ) {}

  @Get('payments')
  @HttpCode(HttpStatus.OK)
  async getPayments(
    @Request() req,
    @Query('status') status?: PaymentStatus,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('minAmount') minAmount?: string,
    @Query('maxAmount') maxAmount?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const dto: GetPaymentsDto = {
      userId: req.user.userId,
      userRole: req.user.role,
      status,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      minAmount: minAmount ? parseInt(minAmount, 10) : undefined,
      maxAmount: maxAmount ? parseInt(maxAmount, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
      offset: offset ? parseInt(offset, 10) : undefined,
    };

    const result = await this.paymentHistoryService.getPayments(dto);

    return {
      success: true,
      data: result.payments,
      pagination: {
        total: result.total,
        limit: dto.limit || 50,
        offset: dto.offset || 0,
      },
    };
  }

  @Get('payments/:id')
  @HttpCode(HttpStatus.OK)
  async getPaymentById(@Param('id') id: string) {
    const payment = await this.paymentHistoryService.getPaymentById(id);
    return {
      success: true,
      data: payment,
    };
  }

  @Get('summary')
  @HttpCode(HttpStatus.OK)
  async getPaymentSummary(@Request() req) {
    const summary = await this.paymentHistoryService.getPaymentSummary(
      req.user.userId,
      req.user.role,
    );

    return {
      success: true,
      data: summary,
    };
  }

  @Get('statistics')
  @HttpCode(HttpStatus.OK)
  async getPaymentStatistics(
    @Request() req,
    @Query('period') period?: 'week' | 'month' | 'year',
  ) {
    const statistics = await this.paymentHistoryService.getPaymentStatistics(
      req.user.userId,
      req.user.role,
      period,
    );

    return {
      success: true,
      data: statistics,
    };
  }

  @Post('invoices/generate')
  @HttpCode(HttpStatus.CREATED)
  async generateInvoice(@Body() dto: GenerateInvoiceDto) {
    const invoice = await this.paymentHistoryService.generateInvoice(dto);
    return {
      success: true,
      message: 'Invoice generated successfully',
      data: invoice,
    };
  }

  @Get('invoices')
  @HttpCode(HttpStatus.OK)
  async getInvoices(
    @Request() req,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const result = await this.paymentHistoryService.getInvoices(
      req.user.userId,
      req.user.role,
      limit ? parseInt(limit, 10) : undefined,
      offset ? parseInt(offset, 10) : undefined,
    );

    return {
      success: true,
      data: result.invoices,
      pagination: {
        total: result.total,
        limit: limit ? parseInt(limit, 10) : 50,
        offset: offset ? parseInt(offset, 10) : 0,
      },
    };
  }

  @Get('invoices/:id')
  @HttpCode(HttpStatus.OK)
  async getInvoiceById(@Param('id') id: string) {
    const invoice = await this.paymentHistoryService.getInvoiceById(id);
    return {
      success: true,
      data: invoice,
    };
  }
}
