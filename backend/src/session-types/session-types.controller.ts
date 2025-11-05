import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { SessionTypesService } from './session-types.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('session-types')
export class SessionTypesController {
  constructor(private readonly sessionTypesService: SessionTypesService) {}

  // Create new session type
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async createSessionType(
    @Request() req,
    @Body()
    createDto: {
      name: string;
      description: string;
      durationMinutes: number;
      priceGBP: number;
      isActive?: boolean;
    },
  ) {
    return this.sessionTypesService.createSessionType(
      req.user.userId,
      createDto,
    );
  }

  // Get all session types for authenticated practitioner
  @Get('my-sessions')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async getMySessionTypes(
    @Request() req,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.sessionTypesService.getSessionTypes(
      req.user.userId,
      includeInactive === 'true',
    );
  }

  // Get session types for a specific practitioner (public)
  @Get('practitioner/:practitionerId')
  async getPractitionerSessionTypes(
    @Param('practitionerId') practitionerId: string,
  ) {
    return this.sessionTypesService.getSessionTypes(practitionerId, false);
  }

  // Get single session type by ID
  @Get(':id')
  async getSessionTypeById(@Param('id') sessionTypeId: string) {
    return this.sessionTypesService.getSessionTypeById(sessionTypeId);
  }

  // Update session type
  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async updateSessionType(
    @Request() req,
    @Param('id') sessionTypeId: string,
    @Body()
    updateDto: {
      name?: string;
      description?: string;
      durationMinutes?: number;
      priceGBP?: number;
      isActive?: boolean;
    },
  ) {
    return this.sessionTypesService.updateSessionType(
      req.user.userId,
      sessionTypeId,
      updateDto,
    );
  }

  // Delete (deactivate) session type
  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async deleteSessionType(@Request() req, @Param('id') sessionTypeId: string) {
    return this.sessionTypesService.deleteSessionType(
      req.user.userId,
      sessionTypeId,
    );
  }
}
