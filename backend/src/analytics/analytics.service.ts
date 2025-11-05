import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AppointmentStatus, PaymentStatus } from '@prisma/client';

interface DateRange {
  startDate?: Date;
  endDate?: Date;
}

@Injectable()
export class AnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  // Get client analytics dashboard
  async getClientAnalytics(userId: string, dateRange?: DateRange) {
    const { startDate, endDate } = this.getDateRange(dateRange);

    // Get all appointments for the client
    const appointments = await this.prisma.appointment.findMany({
      where: {
        clientId: userId,
        appointmentDate: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        sessionType: true,
        outcome: true,
        payment: true,
      },
    });

    // Calculate statistics
    const totalAppointments = appointments.length;
    const completedAppointments = appointments.filter(
      (a) => a.status === AppointmentStatus.COMPLETED,
    ).length;
    const upcomingAppointments = appointments.filter(
      (a) =>
        [AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED].includes(
          a.status,
        ) && new Date(a.appointmentDate) > new Date(),
    ).length;
    const cancelledAppointments = appointments.filter(
      (a) => a.status === AppointmentStatus.CANCELLED,
    ).length;

    // Calculate total spent
    const completedPayments = appointments
      .filter((a) => a.payment && a.payment.status === PaymentStatus.COMPLETED)
      .map((a) => a.payment);
    const totalSpent = completedPayments.reduce(
      (sum, payment) => sum + payment.amount,
      0,
    );

    // Get SANA index progression
    const sanaIndexData = await this.prisma.sanaIndex.findMany({
      where: {
        userId,
        createdAt: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: { createdAt: 'asc' },
      select: {
        overallScore: true,
        createdAt: true,
      },
    });

    // Get current SANA index
    const currentSanaIndex = await this.prisma.sanaIndex.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    // Get outcome statistics
    const outcomes = appointments
      .filter((a) => a.outcome)
      .map((a) => a.outcome);
    const averageOutcomeScore =
      outcomes.length > 0
        ? outcomes.reduce((sum, o) => sum + o.overallScore, 0) / outcomes.length
        : 0;

    // Get session type distribution
    const sessionTypeDistribution = this.calculateDistribution(
      appointments.map((a) => a.sessionType.name),
    );

    // Get monthly appointment trend
    const monthlyTrend = this.calculateMonthlyTrend(appointments, startDate, endDate);

    return {
      overview: {
        totalAppointments,
        completedAppointments,
        upcomingAppointments,
        cancelledAppointments,
        totalSpent: totalSpent / 100, // Convert from pence to pounds
        averageOutcomeScore: Math.round(averageOutcomeScore * 10) / 10,
        currentSanaIndex: currentSanaIndex?.overallScore || 0,
      },
      sanaIndexProgression: sanaIndexData.map((s) => ({
        score: s.overallScore,
        date: s.createdAt,
      })),
      sessionTypeDistribution,
      monthlyTrend,
      dateRange: {
        startDate,
        endDate,
      },
    };
  }

  // Get practitioner analytics dashboard
  async getPractitionerAnalytics(userId: string, dateRange?: DateRange) {
    const { startDate, endDate } = this.getDateRange(dateRange);

    // Verify user is a practitioner
    const practitioner = await this.prisma.practitionerProfile.findUnique({
      where: { userId },
    });

    if (!practitioner) {
      throw new ForbiddenException('User is not a practitioner');
    }

    // Get all appointments for the practitioner
    const appointments = await this.prisma.appointment.findMany({
      where: {
        practitionerId: userId,
        appointmentDate: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        sessionType: true,
        payment: true,
        client: {
          include: {
            user: true,
          },
        },
      },
    });

    // Calculate statistics
    const totalAppointments = appointments.length;
    const completedAppointments = appointments.filter(
      (a) => a.status === AppointmentStatus.COMPLETED,
    ).length;
    const upcomingAppointments = appointments.filter(
      (a) =>
        [AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED].includes(
          a.status,
        ) && new Date(a.appointmentDate) > new Date(),
    ).length;
    const cancelledAppointments = appointments.filter(
      (a) => a.status === AppointmentStatus.CANCELLED,
    ).length;

    // Calculate total earnings
    const completedPayments = appointments
      .filter((a) => a.payment && a.payment.status === PaymentStatus.COMPLETED)
      .map((a) => a.payment);
    const totalEarnings = completedPayments.reduce(
      (sum, payment) => sum + payment.amount,
      0,
    );

    // Calculate unique clients
    const uniqueClientIds = new Set(appointments.map((a) => a.clientId));
    const totalClients = uniqueClientIds.size;

    // Calculate repeat client rate
    const clientAppointmentCounts = appointments.reduce((acc, a) => {
      acc[a.clientId] = (acc[a.clientId] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    const repeatClients = Object.values(clientAppointmentCounts).filter(
      (count) => count > 1,
    ).length;
    const repeatClientRate =
      totalClients > 0 ? (repeatClients / totalClients) * 100 : 0;

    // Get session type distribution
    const sessionTypeDistribution = this.calculateDistribution(
      appointments.map((a) => a.sessionType.name),
    );

    // Get monthly revenue trend
    const monthlyRevenue = this.calculateMonthlyRevenue(
      appointments,
      startDate,
      endDate,
    );

    // Get top clients (by appointment count)
    const topClients = Object.entries(clientAppointmentCounts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([clientId, count]) => {
        const client = appointments.find((a) => a.clientId === clientId)?.client;
        return {
          clientId,
          clientName: client?.user.name || 'Unknown',
          appointmentCount: count,
        };
      });

    // Get upcoming appointments
    const upcomingAppointmentsList = appointments
      .filter(
        (a) =>
          [AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED].includes(
            a.status,
          ) && new Date(a.appointmentDate) > new Date(),
      )
      .sort(
        (a, b) =>
          new Date(a.appointmentDate).getTime() -
          new Date(b.appointmentDate).getTime(),
      )
      .slice(0, 5)
      .map((a) => ({
        id: a.id,
        clientName: a.client.user.name,
        sessionType: a.sessionType.name,
        appointmentDate: a.appointmentDate,
        status: a.status,
      }));

    return {
      overview: {
        totalAppointments,
        completedAppointments,
        upcomingAppointments,
        cancelledAppointments,
        totalEarnings: totalEarnings / 100, // Convert from pence to pounds
        totalClients,
        repeatClientRate: Math.round(repeatClientRate * 10) / 10,
      },
      sessionTypeDistribution,
      monthlyRevenue: monthlyRevenue.map((m) => ({
        ...m,
        revenue: m.revenue / 100, // Convert to pounds
      })),
      topClients,
      upcomingAppointments: upcomingAppointmentsList,
      dateRange: {
        startDate,
        endDate,
      },
    };
  }

  // Helper: Get date range (default to last 90 days)
  private getDateRange(dateRange?: DateRange): {
    startDate: Date;
    endDate: Date;
  } {
    const endDate = dateRange?.endDate || new Date();
    const startDate =
      dateRange?.startDate ||
      new Date(endDate.getTime() - 90 * 24 * 60 * 60 * 1000);
    return { startDate, endDate };
  }

  // Helper: Calculate distribution
  private calculateDistribution(
    items: string[],
  ): Array<{ name: string; count: number; percentage: number }> {
    const counts = items.reduce((acc, item) => {
      acc[item] = (acc[item] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const total = items.length;
    return Object.entries(counts)
      .map(([name, count]) => ({
        name,
        count,
        percentage: total > 0 ? Math.round((count / total) * 100 * 10) / 10 : 0,
      }))
      .sort((a, b) => b.count - a.count);
  }

  // Helper: Calculate monthly trend
  private calculateMonthlyTrend(
    appointments: any[],
    startDate: Date,
    endDate: Date,
  ): Array<{ month: string; count: number }> {
    const monthlyData: Record<string, number> = {};

    appointments.forEach((appointment) => {
      const date = new Date(appointment.appointmentDate);
      const monthKey = date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
      monthlyData[monthKey] = (monthlyData[monthKey] || 0) + 1;
    });

    // Fill in missing months
    const result: Array<{ month: string; count: number }> = [];
    const current = new Date(startDate);
    while (current <= endDate) {
      const monthKey = current.getFullYear() + '-' + String(current.getMonth() + 1).padStart(2, '0');
      result.push({
        month: monthKey,
        count: monthlyData[monthKey] || 0,
      });
      current.setMonth(current.getMonth() + 1);
    }

    return result;
  }

  // Helper: Calculate monthly revenue
  private calculateMonthlyRevenue(
    appointments: any[],
    startDate: Date,
    endDate: Date,
  ): Array<{ month: string; revenue: number; count: number }> {
    const monthlyData: Record<string, { revenue: number; count: number }> = {};

    appointments
      .filter((a) => a.payment && a.payment.status === PaymentStatus.COMPLETED)
      .forEach((appointment) => {
        const date = new Date(appointment.appointmentDate);
        const monthKey = date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
        if (!monthlyData[monthKey]) {
          monthlyData[monthKey] = { revenue: 0, count: 0 };
        }
        monthlyData[monthKey].revenue += appointment.payment.amount;
        monthlyData[monthKey].count += 1;
      });

    // Fill in missing months
    const result: Array<{ month: string; revenue: number; count: number }> = [];
    const current = new Date(startDate);
    while (current <= endDate) {
      const monthKey = current.getFullYear() + '-' + String(current.getMonth() + 1).padStart(2, '0');
      result.push({
        month: monthKey,
        revenue: monthlyData[monthKey]?.revenue || 0,
        count: monthlyData[monthKey]?.count || 0,
      });
      current.setMonth(current.getMonth() + 1);
    }

    return result;
  }
}
