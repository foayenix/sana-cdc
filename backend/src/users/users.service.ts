import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
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
   * Delete user account
   */
  async deleteAccount(userId: string) {
    await this.prisma.user.delete({
      where: { id: userId },
    });

    return {
      success: true,
      message: 'Account deleted successfully',
    };
  }
}
