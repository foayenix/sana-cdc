import { Injectable, NotFoundException, UnauthorizedException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { DeleteAccountDto } from './dto/delete-account.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get user profile by ID
   */
  async getUserById(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        profilePhoto: true,
        createdAt: true,
        clientProfile: true,
        practitionerProfile: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      success: true,
      data: user,
    };
  }

  /**
   * Update user profile
   */
  async updateProfile(userId: string, updateData: { name?: string; profilePhoto?: string }) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        profilePhoto: true,
        createdAt: true,
      },
    });

    return {
      success: true,
      data: user,
    };
  }

  /**
   * Delete user account (GDPR compliant)
   */
  async deleteAccount(userId: string, deleteDto: DeleteAccountDto) {
    // Get user with password hash
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        passwordHash: true,
        role: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Verify password for security
    if (user.passwordHash) {
      const isPasswordValid = await bcrypt.compare(deleteDto.password, user.passwordHash);
      if (!isPasswordValid) {
        throw new UnauthorizedException('Invalid password');
      }
    }

    // Log deletion for GDPR compliance
    this.logger.log(
      `Account deletion requested: userId=${userId}, email=${user.email}, reason=${deleteDto.reason || 'Not provided'}`,
    );

    // Delete user (cascade will handle related data)
    await this.prisma.user.delete({
      where: { id: userId },
    });

    this.logger.log(`Account successfully deleted: userId=${userId}`);

    return {
      success: true,
      message: 'Account deleted successfully',
    };
  }

  /**
   * Export user data (GDPR data portability)
   */
  async exportUserData(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        clientProfile: {
          include: {
            questionnaireResponses: true,
            dailyCheckins: true,
            journals: true,
            outcomes: true,
          },
        },
        practitionerProfile: {
          include: {
            sessionTypes: true,
            stripeAccount: true,
            reviews: true,
          },
        },
        clientAppointments: {
          include: {
            sessionType: true,
            sessionNote: true,
            outcome: true,
            review: true,
          },
        },
        practitionerAppointments: {
          include: {
            sessionType: true,
            sessionNote: true,
          },
        },
        notifications: true,
        notificationPreference: true,
        clientPayments: true,
        practitionerPayments: true,
        sentMessages: true,
        receivedMessages: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Remove sensitive fields
    const { passwordHash, ...userData } = user;

    this.logger.log(`Data export requested: userId=${userId}, email=${user.email}`);

    return {
      success: true,
      data: {
        exportDate: new Date().toISOString(),
        user: userData,
        notice: 'This is your complete personal data stored in SANA CDC. You have the right to request deletion of this data at any time.',
      },
    };
  }
}
