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
  HttpCode,
  HttpStatus,
  Request,
} from '@nestjs/common';
import {
  JournalService,
  CreateJournalEntryDto,
  UpdateJournalEntryDto,
  GetJournalEntriesDto,
} from './journal.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('journal')
@UseGuards(JwtAuthGuard)
export class JournalController {
  constructor(private readonly journalService: JournalService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createEntry(@Request() req, @Body() dto: Omit<CreateJournalEntryDto, 'clientId'>) {
    const clientProfile = await this.journalService['prisma'].clientProfile.findUnique({
      where: { userId: req.user.userId },
      select: { id: true },
    });

    if (!clientProfile) {
      return {
        success: false,
        message: 'Client profile not found',
      };
    }

    const entry = await this.journalService.createEntry({
      ...dto,
      clientId: clientProfile.id,
    });

    return {
      success: true,
      message: 'Journal entry created successfully',
      data: entry,
    };
  }

  @Get()
  @HttpCode(HttpStatus.OK)
  async getEntries(
    @Request() req,
    @Query('tags') tags?: string,
    @Query('mood') mood?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const clientProfile = await this.journalService['prisma'].clientProfile.findUnique({
      where: { userId: req.user.userId },
      select: { id: true },
    });

    if (!clientProfile) {
      return {
        success: false,
        message: 'Client profile not found',
      };
    }

    const dto: GetJournalEntriesDto = {
      clientId: clientProfile.id,
      tags: tags ? tags.split(',') : undefined,
      mood: mood ? parseInt(mood, 10) : undefined,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
      offset: offset ? parseInt(offset, 10) : undefined,
    };

    const result = await this.journalService.getEntries(dto);

    return {
      success: true,
      data: result.entries,
      pagination: {
        total: result.total,
        limit: dto.limit || 50,
        offset: dto.offset || 0,
      },
    };
  }

  @Get('stats')
  @HttpCode(HttpStatus.OK)
  async getStats(@Request() req) {
    const clientProfile = await this.journalService['prisma'].clientProfile.findUnique({
      where: { userId: req.user.userId },
      select: { id: true },
    });

    if (!clientProfile) {
      return {
        success: false,
        message: 'Client profile not found',
      };
    }

    const stats = await this.journalService.getJournalStats(clientProfile.id);

    return {
      success: true,
      data: stats,
    };
  }

  @Get('search')
  @HttpCode(HttpStatus.OK)
  async searchEntries(
    @Request() req,
    @Query('q') searchQuery: string,
    @Query('limit') limit?: string,
  ) {
    const clientProfile = await this.journalService['prisma'].clientProfile.findUnique({
      where: { userId: req.user.userId },
      select: { id: true },
    });

    if (!clientProfile) {
      return {
        success: false,
        message: 'Client profile not found',
      };
    }

    const entries = await this.journalService.searchEntries(
      clientProfile.id,
      searchQuery,
      limit ? parseInt(limit, 10) : undefined,
    );

    return {
      success: true,
      data: entries,
    };
  }

  @Get('tags')
  @HttpCode(HttpStatus.OK)
  async getUniqueTags(@Request() req) {
    const clientProfile = await this.journalService['prisma'].clientProfile.findUnique({
      where: { userId: req.user.userId },
      select: { id: true },
    });

    if (!clientProfile) {
      return {
        success: false,
        message: 'Client profile not found',
      };
    }

    const tags = await this.journalService.getUniqueTags(clientProfile.id);

    return {
      success: true,
      data: tags,
    };
  }

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async getEntryById(@Param('id') id: string) {
    const entry = await this.journalService.getEntryById(id);

    return {
      success: true,
      data: entry,
    };
  }

  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async updateEntry(@Param('id') id: string, @Body() dto: UpdateJournalEntryDto) {
    const entry = await this.journalService.updateEntry(id, dto);

    return {
      success: true,
      message: 'Journal entry updated successfully',
      data: entry,
    };
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async deleteEntry(@Param('id') id: string) {
    const result = await this.journalService.deleteEntry(id);

    return {
      success: true,
      message: result.message,
    };
  }
}
