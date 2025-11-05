import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { OutcomesService } from './outcomes.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('outcomes')
export class OutcomesController {
  constructor(private readonly outcomesService: OutcomesService) {}

  // Create client outcome (practitioner only, after completed appointment)
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async createOutcome(
    @Request() req,
    @Body()
    createDto: {
      appointmentId: string;
      outcomeScore: number;
      improvementNotes?: string;
      goalsAchieved?: string[];
      nextSteps?: string;
    },
  ) {
    return this.outcomesService.createOutcome(req.user.userId, createDto);
  }

  // Get outcome statistics for practitioner (must be before /:id route)
  @Get('stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async getPractitionerOutcomeStats(@Request() req) {
    return this.outcomesService.getPractitionerOutcomeStats(req.user.userId);
  }

  // Get all outcomes for authenticated user
  @Get()
  @UseGuards(JwtAuthGuard)
  async getOutcomes(@Request() req) {
    if (req.user.role === UserRole.PRACTITIONER) {
      return this.outcomesService.getPractitionerOutcomes(req.user.userId);
    } else if (req.user.role === UserRole.CLIENT) {
      return this.outcomesService.getClientOutcomes(req.user.userId);
    } else {
      return [];
    }
  }

  // Get single outcome by ID
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getOutcome(@Request() req, @Param('id') outcomeId: string) {
    return this.outcomesService.getOutcome(outcomeId, req.user.userId);
  }

  // Update outcome (practitioner only)
  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async updateOutcome(
    @Request() req,
    @Param('id') outcomeId: string,
    @Body()
    updateDto: {
      outcomeScore?: number;
      improvementNotes?: string;
      goalsAchieved?: string[];
      nextSteps?: string;
    },
  ) {
    return this.outcomesService.updateOutcome(
      outcomeId,
      req.user.userId,
      updateDto,
    );
  }

  // Delete outcome (practitioner only)
  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async deleteOutcome(@Request() req, @Param('id') outcomeId: string) {
    return this.outcomesService.deleteOutcome(outcomeId, req.user.userId);
  }
}
