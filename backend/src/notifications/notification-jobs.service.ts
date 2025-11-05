import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import { NotificationType, AppointmentStatus } from '@prisma/client';

@Injectable()
export class NotificationJobsService {
  private readonly logger = new Logger(NotificationJobsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // Run every hour to check for upcoming appointments
  @Cron(CronExpression.EVERY_HOUR)
  async send24HourReminders() {
    this.logger.log('Running 24-hour appointment reminder job');

    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in25Hours = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    try {
      // Find appointments that are 24 hours away
      const appointments = await this.prisma.appointment.findMany({
        where: {
          appointmentDate: {
            gte: in24Hours,
            lt: in25Hours,
          },
          status: {
            in: [AppointmentStatus.CONFIRMED, AppointmentStatus.SCHEDULED],
          },
        },
        include: {
          client: true,
          practitioner: {
            include: {
              user: true,
            },
          },
          sessionType: true,
        },
      });

      this.logger.log(`Found ${appointments.length} appointments in 24 hours`);

      for (const appointment of appointments) {
        // Check if 24h reminder was already sent
        const existingNotification = await this.prisma.notification.findFirst({
          where: {
            userId: appointment.clientId,
            type: NotificationType.APPOINTMENT_REMINDER_24H,
            data: {
              path: ['appointmentId'],
              equals: appointment.id,
            },
          },
        });

        if (existingNotification) {
          this.logger.log(`24h reminder already sent for appointment ${appointment.id}`);
          continue;
        }

        // Send reminder to client
        const appointmentDateStr = appointment.appointmentDate.toLocaleString('en-GB', {
          day: '2-digit',
          month: 'long',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
        });

        await this.notificationsService.sendNotification({
          userId: appointment.clientId,
          type: NotificationType.APPOINTMENT_REMINDER_24H,
          title: 'Appointment Reminder - Tomorrow',
          message: `Your appointment with ${appointment.practitioner.user.name} for ${appointment.sessionType.name} is scheduled for tomorrow at ${appointmentDateStr}.`,
          data: {
            appointmentId: appointment.id,
            practitionerId: appointment.practitionerId,
            sessionTypeId: appointment.sessionTypeId,
          },
          sendEmail: true,
          sendPush: true,
        });

        this.logger.log(`Sent 24h reminder for appointment ${appointment.id}`);
      }
    } catch (error) {
      this.logger.error('Error sending 24h reminders:', error);
    }
  }

  // Run every 15 minutes to check for appointments in 1 hour
  @Cron(CronExpression.EVERY_30_MINUTES)
  async send1HourReminders() {
    this.logger.log('Running 1-hour appointment reminder job');

    const now = new Date();
    const in1Hour = new Date(now.getTime() + 60 * 60 * 1000);
    const in90Minutes = new Date(now.getTime() + 90 * 60 * 1000);

    try {
      // Find appointments that are 1 hour away
      const appointments = await this.prisma.appointment.findMany({
        where: {
          appointmentDate: {
            gte: in1Hour,
            lt: in90Minutes,
          },
          status: {
            in: [AppointmentStatus.CONFIRMED, AppointmentStatus.SCHEDULED],
          },
        },
        include: {
          client: true,
          practitioner: {
            include: {
              user: true,
            },
          },
          sessionType: true,
        },
      });

      this.logger.log(`Found ${appointments.length} appointments in 1 hour`);

      for (const appointment of appointments) {
        // Check if 1h reminder was already sent
        const existingNotification = await this.prisma.notification.findFirst({
          where: {
            userId: appointment.clientId,
            type: NotificationType.APPOINTMENT_REMINDER_1H,
            data: {
              path: ['appointmentId'],
              equals: appointment.id,
            },
          },
        });

        if (existingNotification) {
          this.logger.log(`1h reminder already sent for appointment ${appointment.id}`);
          continue;
        }

        // Send reminder to client
        const appointmentDateStr = appointment.appointmentDate.toLocaleString('en-GB', {
          hour: '2-digit',
          minute: '2-digit',
        });

        await this.notificationsService.sendNotification({
          userId: appointment.clientId,
          type: NotificationType.APPOINTMENT_REMINDER_1H,
          title: 'Appointment Starting Soon',
          message: `Your appointment with ${appointment.practitioner.user.name} starts in approximately 1 hour at ${appointmentDateStr}.`,
          data: {
            appointmentId: appointment.id,
            practitionerId: appointment.practitionerId,
            sessionTypeId: appointment.sessionTypeId,
          },
          sendEmail: true,
          sendPush: true,
        });

        this.logger.log(`Sent 1h reminder for appointment ${appointment.id}`);
      }
    } catch (error) {
      this.logger.error('Error sending 1h reminders:', error);
    }
  }

  // Clean up old notifications (run daily at 2 AM)
  @Cron('0 2 * * *')
  async cleanupOldNotifications() {
    this.logger.log('Running notification cleanup job');

    try {
      const result = await this.notificationsService.deleteOldNotifications(90);
      this.logger.log(`Cleaned up ${result.count} old notifications`);
    } catch (error) {
      this.logger.error('Error cleaning up notifications:', error);
    }
  }
}
