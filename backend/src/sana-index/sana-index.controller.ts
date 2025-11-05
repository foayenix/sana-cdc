import { Controller, Get, Post, UseGuards, Request, Param } from '@nestjs/common';
import { SanaIndexService } from './sana-index.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('sana-index')
export class SanaIndexController {
  constructor(private readonly sanaIndexService: SanaIndexService) {}

  // Get own SANA Index breakdown (practitioner only)
  @Get('my-index')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async getMyIndex(@Request() req) {
    return this.sanaIndexService.calculateSanaIndex(req.user.userId);
  }

  // Recalculate own SANA Index (practitioner only)
  @Post('recalculate')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async recalculateMyIndex(@Request() req) {
    await this.sanaIndexService.updateSanaIndex(req.user.userId);
    return {
      success: true,
      message: 'SANA Index recalculated successfully',
    };
  }

  // Get SANA Index for a specific practitioner (public)
  @Get('practitioner/:id')
  async getPractitionerIndex(@Param('id') practitionerId: string) {
    const breakdown = await this.sanaIndexService.calculateSanaIndex(practitionerId);
    // Only return total score for public endpoint
    return {
      totalScore: breakdown.totalScore,
    };
  }

  // ADMIN: Recalculate all SANA Indexes
  @Post('admin/recalculate-all')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async recalculateAllIndexes() {
    await this.sanaIndexService.recalculateAllSanaIndexes();
    return {
      success: true,
      message: 'SANA Index recalculation initiated for all practitioners',
    };
  }
}
