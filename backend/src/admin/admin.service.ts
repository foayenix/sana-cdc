import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { VerificationStatus, UserRole } from '@prisma/client';

export interface GetUsersDto {
  role?: UserRole;
  search?: string;
  limit?: number;
  offset?: number;
}

export interface UpdateUserStatusDto {
  isActive?: boolean;
  role?: UserRole;
}

export interface PlatformStatsDto {
  totalUsers: number;
  totalClients: number;
  totalPractitioners: number;
  totalAppointments: number;
  totalRevenue: number;
  pendingVerifications: number;
  activeConversations: number;
  totalReviews: number;
}

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(private prisma: PrismaService) {}

  async getPlatformStats(): Promise<PlatformStatsDto> {
    const totalUsers = await this.prisma.user.count();
    const totalClients = await this.prisma.clientProfile.count();
    const totalPractitioners = await this.prisma.practitionerProfile.count();
    const totalAppointments = await this.prisma.appointment.count();

    const payments = await this.prisma.payment.findMany({
      where: { status: 'COMPLETED' },
      select: { amount: true },
    });
    const totalRevenue = payments.reduce((sum, p) => sum + p.amount, 0);

    const pendingVerifications = await this.prisma.practitionerProfile.count({
      where: { verificationStatus: VerificationStatus.PENDING },
    });

    const activeConversations = await this.prisma.conversation.count({
      where: {
        lastMessageAt: {
          gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        },
      },
    });

    const totalReviews = await this.prisma.review.count();

    return {
      totalUsers,
      totalClients,
      totalPractitioners,
      totalAppointments,
      totalRevenue,
      pendingVerifications,
      activeConversations,
      totalReviews,
    };
  }

  async getUsers(dto: GetUsersDto) {
    const { role, search, limit = 50, offset = 0 } = dto;

    const where: any = {};
    if (role) where.role = role;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const users = await this.prisma.user.findMany({
      where,
      include: {
        clientProfile: true,
        practitionerProfile: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const total = await this.prisma.user.count({ where });

    return { users, total };
  }

  async getUserById(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        clientProfile: {
          include: {
            dailyCheckins: { take: 10, orderBy: { date: 'desc' } },
            journals: { take: 5, orderBy: { createdAt: 'desc' } },
          },
        },
        practitionerProfile: {
          include: {
            sessionTypes: true,
            reviews: { take: 5, orderBy: { createdAt: 'desc' } },
          },
        },
        clientAppointments: { take: 10, orderBy: { scheduledAt: 'desc' } },
        practitionerAppointments: { take: 10, orderBy: { scheduledAt: 'desc' } },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async getPendingVerifications(limit = 50, offset = 0) {
    const practitioners = await this.prisma.practitionerProfile.findMany({
      where: {
        verificationStatus: { in: [VerificationStatus.PENDING, VerificationStatus.UNDER_REVIEW] },
      },
      include: {
        user: {
          select: { id: true, name: true, email: true, createdAt: true },
        },
      },
      orderBy: { createdAt: 'asc' },
      take: limit,
      skip: offset,
    });

    const total = await this.prisma.practitionerProfile.count({
      where: {
        verificationStatus: { in: [VerificationStatus.PENDING, VerificationStatus.UNDER_REVIEW] },
      },
    });

    return { practitioners, total };
  }

  async updateVerificationStatus(
    practitionerId: string,
    status: VerificationStatus,
    adminId: string,
  ) {
    const practitioner = await this.prisma.practitionerProfile.update({
      where: { id: practitionerId },
      data: { verificationStatus: status },
      include: { user: true },
    });

    this.logger.log('Verification status updated: ' + practitionerId + ' to ' + status);

    return practitioner;
  }

  async getRecentReviews(limit = 50, offset = 0) {
    const reviews = await this.prisma.review.findMany({
      include: {
        practitioner: {
          include: { user: { select: { name: true } } },
        },
        client: {
          include: { user: { select: { name: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const total = await this.prisma.review.count();

    return { reviews, total };
  }

  async updateReviewStatus(reviewId: string, isPublished: boolean) {
    const review = await this.prisma.review.update({
      where: { id: reviewId },
      data: { isPublished },
    });

    return review;
  }

  async getRecentAppointments(limit = 50, offset = 0) {
    const appointments = await this.prisma.appointment.findMany({
      include: {
        client: { select: { id: true, name: true, email: true } },
        practitioner: { select: { id: true, name: true, email: true } },
        sessionType: { select: { name: true, duration: true, price: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const total = await this.prisma.appointment.count();

    return { appointments, total };
  }

  async getUserActivityStats(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const appointmentCount = await this.prisma.appointment.count({
      where: {
        OR: [{ clientId: userId }, { practitionerId: userId }],
      },
    });

    const messageCount = await this.prisma.message.count({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
    });

    const reviewsGiven = await this.prisma.review.count({
      where: { clientId: user.clientProfile?.id || '' },
    });

    const reviewsReceived = await this.prisma.review.count({
      where: { practitionerId: user.practitionerProfile?.id || '' },
    });

    return {
      appointmentCount,
      messageCount,
      reviewsGiven,
      reviewsReceived,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
    };
  }
}
