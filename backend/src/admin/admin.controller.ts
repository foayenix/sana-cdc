import {
  Controller,
  Get,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AdminService, GetUsersDto, UpdateUserStatusDto } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { VerificationStatus, UserRole } from '@prisma/client';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  @HttpCode(HttpStatus.OK)
  async getPlatformStats() {
    const stats = await this.adminService.getPlatformStats();
    return {
      success: true,
      data: stats,
    };
  }

  @Get('users')
  @HttpCode(HttpStatus.OK)
  async getUsers(
    @Query('role') role?: UserRole,
    @Query('search') search?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const dto: GetUsersDto = {
      role,
      search,
      limit: limit ? parseInt(limit, 10) : undefined,
      offset: offset ? parseInt(offset, 10) : undefined,
    };

    const result = await this.adminService.getUsers(dto);
    return {
      success: true,
      data: result.users,
      pagination: {
        total: result.total,
        limit: dto.limit || 50,
        offset: dto.offset || 0,
      },
    };
  }

  @Get('users/:userId')
  @HttpCode(HttpStatus.OK)
  async getUserById(@Param('userId') userId: string) {
    const user = await this.adminService.getUserById(userId);
    return {
      success: true,
      data: user,
    };
  }

  @Get('users/:userId/activity')
  @HttpCode(HttpStatus.OK)
  async getUserActivityStats(@Param('userId') userId: string) {
    const stats = await this.adminService.getUserActivityStats(userId);
    return {
      success: true,
      data: stats,
    };
  }

  @Get('verifications')
  @HttpCode(HttpStatus.OK)
  async getPendingVerifications(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const result = await this.adminService.getPendingVerifications(
      limit ? parseInt(limit, 10) : undefined,
      offset ? parseInt(offset, 10) : undefined,
    );

    return {
      success: true,
      data: result.practitioners,
      pagination: {
        total: result.total,
        limit: limit ? parseInt(limit, 10) : 50,
        offset: offset ? parseInt(offset, 10) : 0,
      },
    };
  }

  @Put('verifications/:practitionerId/status')
  @HttpCode(HttpStatus.OK)
  async updateVerificationStatus(
    @Param('practitionerId') practitionerId: string,
    @Body('status') status: VerificationStatus,
    @Body('adminId') adminId: string,
  ) {
    const practitioner = await this.adminService.updateVerificationStatus(
      practitionerId,
      status,
      adminId,
    );

    return {
      success: true,
      message: 'Verification status updated successfully',
      data: practitioner,
    };
  }

  @Get('reviews')
  @HttpCode(HttpStatus.OK)
  async getRecentReviews(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const result = await this.adminService.getRecentReviews(
      limit ? parseInt(limit, 10) : undefined,
      offset ? parseInt(offset, 10) : undefined,
    );

    return {
      success: true,
      data: result.reviews,
      pagination: {
        total: result.total,
        limit: limit ? parseInt(limit, 10) : 50,
        offset: offset ? parseInt(offset, 10) : 0,
      },
    };
  }

  @Put('reviews/:reviewId/status')
  @HttpCode(HttpStatus.OK)
  async updateReviewStatus(
    @Param('reviewId') reviewId: string,
    @Body('isPublished') isPublished: boolean,
  ) {
    const review = await this.adminService.updateReviewStatus(
      reviewId,
      isPublished,
    );

    return {
      success: true,
      message: 'Review status updated successfully',
      data: review,
    };
  }

  @Get('appointments')
  @HttpCode(HttpStatus.OK)
  async getRecentAppointments(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const result = await this.adminService.getRecentAppointments(
      limit ? parseInt(limit, 10) : undefined,
      offset ? parseInt(offset, 10) : undefined,
    );

    return {
      success: true,
      data: result.appointments,
      pagination: {
        total: result.total,
        limit: limit ? parseInt(limit, 10) : 50,
        offset: offset ? parseInt(offset, 10) : 0,
      },
    };
  }
}
