import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationType } from '@prisma/client';
import * as nodemailer from 'nodemailer';

interface SendNotificationDto {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  data?: any;
  sendEmail?: boolean;
  sendPush?: boolean;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private emailTransporter: nodemailer.Transporter;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    // Initialize email transporter
    const emailConfig = {
      host: this.configService.get('EMAIL_HOST', 'smtp.gmail.com'),
      port: this.configService.get('EMAIL_PORT', 587),
      secure: false,
      auth: {
        user: this.configService.get('EMAIL_USER'),
        pass: this.configService.get('EMAIL_PASSWORD'),
      },
    };

    this.emailTransporter = nodemailer.createTransporter(emailConfig);
  }

  // Create and send a notification
  async sendNotification(dto: SendNotificationDto) {
    const {
      userId,
      type,
      title,
      message,
      data,
      sendEmail = true,
      sendPush = true,
    } = dto;

    // Get user and preferences
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { notificationPreference: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Create notification record
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        type,
        title,
        message,
        data,
      },
    });

    // Check preferences
    const prefs = user.notificationPreference;
    const shouldSendEmail =
      sendEmail && prefs?.emailEnabled && this.shouldSendNotificationType(prefs, type);
    const shouldSendPush =
      sendPush && prefs?.pushEnabled && this.shouldSendNotificationType(prefs, type);

    // Send via email
    if (shouldSendEmail) {
      try {
        await this.sendEmail(user.email, user.name, title, message, type, data);
        await this.prisma.notification.update({
          where: { id: notification.id },
          data: { emailSent: true },
        });
      } catch (error) {
        this.logger.error(\`Failed to send email to \${user.email}:\`, error);
      }
    }

    // Send via push notification (placeholder - requires Firebase integration)
    if (shouldSendPush) {
      try {
        await this.sendPushNotification(userId, title, message, data);
        await this.prisma.notification.update({
          where: { id: notification.id },
          data: { pushSent: true },
        });
      } catch (error) {
        this.logger.error(\`Failed to send push notification to \${userId}:\`, error);
      }
    }

    // Mark as sent
    await this.prisma.notification.update({
      where: { id: notification.id },
      data: { sent: true, sentAt: new Date() },
    });

    return notification;
  }

  // Send email notification
  private async sendEmail(
    email: string,
    name: string,
    title: string,
    message: string,
    type: NotificationType,
    data?: any,
  ) {
    const html = this.generateEmailHtml(name, title, message, type, data);

    await this.emailTransporter.sendMail({
      from: this.configService.get('EMAIL_FROM', 'SANA Wellness <noreply@sana.com>'),
      to: email,
      subject: title,
      html,
    });

    this.logger.log(\`Email sent to \${email}: \${title}\`);
  }

  // Generate email HTML
  private generateEmailHtml(
    name: string,
    title: string,
    message: string,
    type: NotificationType,
    data?: any,
  ): string {
    const primaryColor = '#6200EE';
    const actionButton = this.getActionButton(type, data);

    return \`
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>\${title}</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden;">
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, \${primaryColor} 0%, #9c27b0 100%); padding: 30px 40px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 28px;">SANA Wellness</h1>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 40px;">
              <h2 style="margin: 0 0 20px 0; color: #333; font-size: 24px;">\${title}</h2>
              <p style="margin: 0 0 20px 0; color: #666; font-size: 16px; line-height: 1.6;">
                Hi \${name},
              </p>
              <p style="margin: 0 0 30px 0; color: #666; font-size: 16px; line-height: 1.6;">
                \${message}
              </p>

              \${actionButton}
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 30px 40px; background-color: #f9f9f9; text-align: center; border-top: 1px solid #e0e0e0;">
              <p style="margin: 0 0 10px 0; color: #999; font-size: 14px;">
                SANA Wellness - Your path to wellness
              </p>
              <p style="margin: 0; color: #999; font-size: 12px;">
                <a href="#" style="color: \${primaryColor}; text-decoration: none;">Manage notification preferences</a>
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
    \`;
  }

  // Get action button HTML based on notification type
  private getActionButton(type: NotificationType, data?: any): string {
    const primaryColor = '#6200EE';
    let buttonText = '';
    let buttonLink = '';

    switch (type) {
      case 'APPOINTMENT_CONFIRMATION':
      case 'APPOINTMENT_REMINDER_24H':
      case 'APPOINTMENT_REMINDER_1H':
        buttonText = 'View Appointment';
        buttonLink = data?.appointmentId
          ? \`\${this.configService.get('APP_URL')}/appointments/\${data.appointmentId}\`
          : \`\${this.configService.get('APP_URL')}/appointments\`;
        break;
      case 'PAYMENT_SUCCESS':
        buttonText = 'View Receipt';
        buttonLink = data?.paymentId
          ? \`\${this.configService.get('APP_URL')}/payments/\${data.paymentId}\`
          : \`\${this.configService.get('APP_URL')}/appointments\`;
        break;
      case 'SESSION_NOTE_ADDED':
        buttonText = 'Read Session Note';
        buttonLink = data?.appointmentId
          ? \`\${this.configService.get('APP_URL')}/appointments/\${data.appointmentId}\`
          : \`\${this.configService.get('APP_URL')}/appointments\`;
        break;
      case 'OUTCOME_RECORDED':
        buttonText = 'View Outcome';
        buttonLink = \`\${this.configService.get('APP_URL')}/outcomes\`;
        break;
      default:
        return '';
    }

    if (!buttonText) return '';

    return \`
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td align="center" style="padding: 10px 0;">
            <a href="\${buttonLink}" style="display: inline-block; padding: 14px 40px; background-color: \${primaryColor}; color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px;">
              \${buttonText}
            </a>
          </td>
        </tr>
      </table>
    \`;
  }

  // Send push notification (placeholder - requires Firebase setup)
  private async sendPushNotification(
    userId: string,
    title: string,
    message: string,
    data?: any,
  ) {
    // TODO: Implement Firebase Cloud Messaging
    // This would require:
    // 1. Firebase Admin SDK initialization
    // 2. Store FCM tokens for users
    // 3. Send push notification via FCM

    this.logger.log(\`Push notification would be sent to \${userId}: \${title}\`);
    // For now, just log - actual implementation requires Firebase setup
  }

  // Check if notification type should be sent based on preferences
  private shouldSendNotificationType(
    prefs: any,
    type: NotificationType,
  ): boolean {
    switch (type) {
      case 'APPOINTMENT_REMINDER_24H':
      case 'APPOINTMENT_REMINDER_1H':
        return prefs.appointmentReminders;
      case 'APPOINTMENT_CONFIRMATION':
      case 'APPOINTMENT_CANCELLED':
      case 'APPOINTMENT_RESCHEDULED':
        return prefs.appointmentUpdates;
      case 'PAYMENT_SUCCESS':
      case 'PAYMENT_FAILED':
      case 'PAYMENT_REFUNDED':
        return prefs.paymentNotifications;
      case 'SESSION_NOTE_ADDED':
        return prefs.sessionNotes;
      case 'OUTCOME_RECORDED':
        return prefs.outcomeNotifications;
      case 'NEW_MESSAGE':
        return prefs.messageNotifications;
      case 'SYSTEM_ANNOUNCEMENT':
        return prefs.systemAnnouncements;
      default:
        return true;
    }
  }

  // Get user notifications
  async getUserNotifications(userId: string, limit = 50, offset = 0) {
    const notifications = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const total = await this.prisma.notification.count({
      where: { userId },
    });

    const unreadCount = await this.prisma.notification.count({
      where: { userId, read: false },
    });

    return {
      notifications,
      total,
      unreadCount,
    };
  }

  // Mark notification as read
  async markAsRead(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    if (notification.userId !== userId) {
      throw new BadRequestException('Access denied');
    }

    return await this.prisma.notification.update({
      where: { id: notificationId },
      data: {
        read: true,
        readAt: new Date(),
      },
    });
  }

  // Mark all as read
  async markAllAsRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: {
        read: true,
        readAt: new Date(),
      },
    });

    return { message: 'All notifications marked as read' };
  }

  // Get or create user notification preferences
  async getPreferences(userId: string) {
    let prefs = await this.prisma.notificationPreference.findUnique({
      where: { userId },
    });

    if (!prefs) {
      prefs = await this.prisma.notificationPreference.create({
        data: { userId },
      });
    }

    return prefs;
  }

  // Update notification preferences
  async updatePreferences(userId: string, updates: any) {
    const prefs = await this.getPreferences(userId);

    return await this.prisma.notificationPreference.update({
      where: { id: prefs.id },
      data: updates,
    });
  }

  // Delete old notifications (cleanup job)
  async deleteOldNotifications(daysOld = 90) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await this.prisma.notification.deleteMany({
      where: {
        createdAt: { lt: cutoffDate },
        read: true,
      },
    });

    this.logger.log(\`Deleted \${result.count} old notifications\`);
    return result;
  }
}
