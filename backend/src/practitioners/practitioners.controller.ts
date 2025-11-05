import {
  Controller,
  Get,
  Put,
  Post,
  Body,
  UseGuards,
  Request,
  Query,
  Param,
} from '@nestjs/common';
import { PractitionersService } from './practitioners.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UploadCredentialsDto } from './dto/upload-credentials.dto';
import { UserRole, VerificationStatus } from '@prisma/client';

@Controller('practitioners')
export class PractitionersController {
  constructor(private readonly practitionersService: PractitionersService) {}

  // Get own profile (authenticated practitioner only)
  @Get('profile')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async getProfile(@Request() req) {
    return this.practitionersService.getProfile(req.user.userId);
  }

  // Update own profile
  @Put('profile')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async updateProfile(@Request() req, @Body() updateDto: UpdateProfileDto) {
    return this.practitionersService.updateProfile(req.user.userId, updateDto);
  }

  // Upload credentials
  @Post('credentials')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async uploadCredentials(
    @Request() req,
    @Body() uploadDto: UploadCredentialsDto,
  ) {
    return this.practitionersService.uploadCredentials(req.user.userId, uploadDto);
  }

  // Set availability
  @Post('availability')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async setAvailability(
    @Request() req,
    @Body() availabilityDto: { availability: any[] },
  ) {
    return this.practitionersService.setAvailability(
      req.user.userId,
      availabilityDto,
    );
  }

  // Get own availability
  @Get('availability')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async getAvailability(@Request() req) {
    return this.practitionersService.getAvailability(req.user.userId);
  }

  // Toggle SANA Index visibility
  @Put('sana-index/visibility')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PRACTITIONER)
  async toggleSanaIndexVisibility(
    @Request() req,
    @Body() body: { isPublic: boolean },
  ) {
    return this.practitionersService.toggleSanaIndexVisibility(
      req.user.userId,
      body.isPublic,
    );
  }

  // PUBLIC: Search practitioners
  @Get('search')
  async searchPractitioners(
    @Query('specialties') specialties?: string,
    @Query('postcode') postcode?: string,
    @Query('minSanaIndex') minSanaIndex?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const filters = {
      specialties: specialties ? specialties.split(',') : undefined,
      postcode,
      minSanaIndex: minSanaIndex ? parseInt(minSanaIndex) : undefined,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    };

    return this.practitionersService.searchPractitioners(filters);
  }

  // PUBLIC: Get practitioner public profile
  @Get(':id/public')
  async getPublicProfile(@Param('id') practitionerId: string) {
    return this.practitionersService.getPublicProfile(practitionerId);
  }

  // ADMIN: Get pending verifications
  @Get('admin/pending-verifications')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async getPendingVerifications() {
    return this.practitionersService.getPendingVerifications();
  }

  // ADMIN: Update verification status
  @Put('admin/:id/verification')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async updateVerificationStatus(
    @Param('id') practitionerId: string,
    @Body() body: { status: VerificationStatus; adminNotes?: string },
  ) {
    return this.practitionersService.updateVerificationStatus(
      practitionerId,
      body.status,
      body.adminNotes,
    );
  }
}
