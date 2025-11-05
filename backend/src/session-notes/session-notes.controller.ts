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
import { SessionNotesService } from './session-notes.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('session-notes')
export class SessionNotesController {
  constructor(private readonly sessionNotesService: SessionNotesService) {}

  // Create session note (practitioner only, after completed appointment)
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async createSessionNote(
    @Request() req,
    @Body()
    createDto: {
      appointmentId: string;
      notes: string;
      privateNotes?: string;
      recommendations?: string;
      followUpRequired?: boolean;
      followUpDate?: string;
    },
  ) {
    const data: any = { ...createDto };
    if (createDto.followUpDate) {
      data.followUpDate = new Date(createDto.followUpDate);
    }

    return this.sessionNotesService.createSessionNote(req.user.userId, data);
  }

  // Get all session notes for authenticated user
  @Get()
  @UseGuards(JwtAuthGuard)
  async getSessionNotes(@Request() req) {
    if (req.user.role === UserRole.PRACTITIONER) {
      return this.sessionNotesService.getPractitionerSessionNotes(
        req.user.userId,
      );
    } else if (req.user.role === UserRole.CLIENT) {
      return this.sessionNotesService.getClientSessionNotes(req.user.userId);
    } else {
      return [];
    }
  }

  // Get single session note by ID
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getSessionNote(@Request() req, @Param('id') sessionNoteId: string) {
    return this.sessionNotesService.getSessionNote(
      sessionNoteId,
      req.user.userId,
    );
  }

  // Update session note (practitioner only)
  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async updateSessionNote(
    @Request() req,
    @Param('id') sessionNoteId: string,
    @Body()
    updateDto: {
      notes?: string;
      privateNotes?: string;
      recommendations?: string;
      followUpRequired?: boolean;
      followUpDate?: string;
    },
  ) {
    const data: any = { ...updateDto };
    if (updateDto.followUpDate) {
      data.followUpDate = new Date(updateDto.followUpDate);
    }

    return this.sessionNotesService.updateSessionNote(
      sessionNoteId,
      req.user.userId,
      data,
    );
  }

  // Delete session note (practitioner only)
  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async deleteSessionNote(@Request() req, @Param('id') sessionNoteId: string) {
    return this.sessionNotesService.deleteSessionNote(
      sessionNoteId,
      req.user.userId,
    );
  }
}
