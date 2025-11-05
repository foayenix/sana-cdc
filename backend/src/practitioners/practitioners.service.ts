import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UploadCredentialsDto } from './dto/upload-credentials.dto';
import { Prisma, VerificationStatus } from '@prisma/client';

interface AvailabilitySlot {
  dayOfWeek: number; // 0-6 (Sunday-Saturday)
  startTime: string; // HH:mm format
  endTime: string; // HH:mm format
}

interface SetAvailabilityDto {
  availability: AvailabilitySlot[];
}

@Injectable()
export class PractitionersService {
  constructor(private readonly prisma: PrismaService) {}

  // Get practitioner's own profile
  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        practitionerProfile: {
          include: {
            sessionTypes: true,
          },
        },
      },
    });

    if (!user || !user.practitionerProfile) {
      throw new NotFoundException('Practitioner profile not found');
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
      profilePhoto: user.profilePhoto,
      profile: user.practitionerProfile,
    };
  }

  // Update practitioner profile
  async updateProfile(userId: string, updateDto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { practitionerProfile: true },
    });

    if (!user || !user.practitionerProfile) {
      throw new NotFoundException('Practitioner profile not found');
    }

    // Update user name and profile photo if provided
    const userUpdateData: Prisma.UserUpdateInput = {};
    if (updateDto.name) userUpdateData.name = updateDto.name;
    if (updateDto.profilePhoto) userUpdateData.profilePhoto = updateDto.profilePhoto;

    // Update practitioner profile
    const profileUpdateData: Prisma.PractitionerProfileUpdateInput = {};
    if (updateDto.practiceName !== undefined) profileUpdateData.practiceName = updateDto.practiceName;
    if (updateDto.bio !== undefined) profileUpdateData.bio = updateDto.bio;
    if (updateDto.postcode !== undefined) profileUpdateData.postcode = updateDto.postcode;
    if (updateDto.specialties !== undefined) profileUpdateData.specialties = updateDto.specialties;
    if (updateDto.yearsOfPractice !== undefined) profileUpdateData.yearsOfPractice = updateDto.yearsOfPractice;
    if (updateDto.professionalBody !== undefined) profileUpdateData.professionalBody = updateDto.professionalBody;
    if (updateDto.qualifications !== undefined) profileUpdateData.qualifications = updateDto.qualifications;
    if (updateDto.insuranceNumber !== undefined) profileUpdateData.insuranceNumber = updateDto.insuranceNumber;
    if (updateDto.aboutMe !== undefined) profileUpdateData.aboutMe = updateDto.aboutMe;
    if (updateDto.approach !== undefined) profileUpdateData.approach = updateDto.approach;

    // Perform updates in a transaction
    const [updatedUser] = await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: userUpdateData,
        include: {
          practitionerProfile: {
            include: { sessionTypes: true },
          },
        },
      }),
      this.prisma.practitionerProfile.update({
        where: { userId: userId },
        data: profileUpdateData,
      }),
    ]);

    return {
      id: updatedUser.id,
      email: updatedUser.email,
      name: updatedUser.name,
      profilePhoto: updatedUser.profilePhoto,
      profile: updatedUser.practitionerProfile,
    };
  }

  // Upload credentials (S3 keys)
  async uploadCredentials(userId: string, uploadDto: UploadCredentialsDto) {
    const profile = await this.prisma.practitionerProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Practitioner profile not found');
    }

    // Append new credential files to existing ones
    const currentFiles = (profile.credentialFiles as string[]) || [];
    const updatedFiles = [...currentFiles, ...uploadDto.credentialFiles];

    const updatedProfile = await this.prisma.practitionerProfile.update({
      where: { userId },
      data: {
        credentialFiles: updatedFiles,
        verificationStatus: VerificationStatus.PENDING, // Reset to pending when new files uploaded
      },
    });

    return {
      success: true,
      message: 'Credentials uploaded successfully. Awaiting admin verification.',
      credentialFiles: updatedProfile.credentialFiles,
      verificationStatus: updatedProfile.verificationStatus,
    };
  }

  // Set availability slots
  async setAvailability(userId: string, availabilityDto: SetAvailabilityDto) {
    const profile = await this.prisma.practitionerProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Practitioner profile not found');
    }

    // Validate availability slots
    for (const slot of availabilityDto.availability) {
      if (slot.dayOfWeek < 0 || slot.dayOfWeek > 6) {
        throw new BadRequestException('Invalid dayOfWeek. Must be 0-6.');
      }
      // Add more validation for time format if needed
    }

    const updatedProfile = await this.prisma.practitionerProfile.update({
      where: { userId },
      data: {
        availabilityData: availabilityDto.availability as any,
      },
    });

    return {
      success: true,
      availability: updatedProfile.availabilityData,
    };
  }

  // Get availability
  async getAvailability(userId: string) {
    const profile = await this.prisma.practitionerProfile.findUnique({
      where: { userId },
      select: { availabilityData: true },
    });

    if (!profile) {
      throw new NotFoundException('Practitioner profile not found');
    }

    return {
      availability: profile.availabilityData || [],
    };
  }

  // Toggle SANA Index visibility
  async toggleSanaIndexVisibility(userId: string, isPublic: boolean) {
    const profile = await this.prisma.practitionerProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Practitioner profile not found');
    }

    const updatedProfile = await this.prisma.practitionerProfile.update({
      where: { userId },
      data: { sanaIndexPublic: isPublic },
    });

    return {
      success: true,
      sanaIndexPublic: updatedProfile.sanaIndexPublic,
    };
  }

  // Search practitioners (public)
  async searchPractitioners(filters: {
    specialties?: string[];
    postcode?: string;
    minSanaIndex?: number;
    page?: number;
    limit?: number;
  }) {
    const { specialties, postcode, minSanaIndex, page = 1, limit = 20 } = filters;

    const where: Prisma.PractitionerProfileWhereInput = {
      verificationStatus: VerificationStatus.VERIFIED, // Only show verified practitioners
    };

    if (specialties && specialties.length > 0) {
      where.specialties = {
        hasSome: specialties,
      };
    }

    if (postcode) {
      where.postcode = postcode;
    }

    if (minSanaIndex !== undefined) {
      where.sanaIndexScore = {
        gte: minSanaIndex,
      };
    }

    const skip = (page - 1) * limit;

    const [practitioners, total] = await this.prisma.$transaction([
      this.prisma.practitionerProfile.findMany({
        where,
        skip,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              name: true,
              profilePhoto: true,
            },
          },
          sessionTypes: true,
        },
        orderBy: {
          sanaIndexScore: 'desc',
        },
      }),
      this.prisma.practitionerProfile.count({ where }),
    ]);

    return {
      practitioners: practitioners.map((p) => ({
        id: p.user.id,
        name: p.user.name,
        profilePhoto: p.user.profilePhoto,
        practiceName: p.practiceName,
        bio: p.bio,
        specialties: p.specialties,
        yearsOfPractice: p.yearsOfPractice,
        postcode: p.postcode,
        sanaIndexScore: p.sanaIndexPublic ? p.sanaIndexScore : null,
        sessionTypes: p.sessionTypes,
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // Get public practitioner profile
  async getPublicProfile(practitionerId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: practitionerId },
      include: {
        practitionerProfile: {
          include: {
            sessionTypes: true,
          },
        },
      },
    });

    if (!user || !user.practitionerProfile) {
      throw new NotFoundException('Practitioner not found');
    }

    const profile = user.practitionerProfile;

    if (profile.verificationStatus !== VerificationStatus.VERIFIED) {
      throw new ForbiddenException('This practitioner profile is not publicly available');
    }

    return {
      id: user.id,
      name: user.name,
      profilePhoto: user.profilePhoto,
      practiceName: profile.practiceName,
      bio: profile.bio,
      aboutMe: profile.aboutMe,
      approach: profile.approach,
      specialties: profile.specialties,
      yearsOfPractice: profile.yearsOfPractice,
      professionalBody: profile.professionalBody,
      qualifications: profile.qualifications,
      postcode: profile.postcode,
      sanaIndexScore: profile.sanaIndexPublic ? profile.sanaIndexScore : null,
      sessionTypes: profile.sessionTypes,
      availabilityData: profile.availabilityData,
    };
  }

  // Admin: Get pending verifications
  async getPendingVerifications() {
    const pendingPractitioners = await this.prisma.practitionerProfile.findMany({
      where: {
        verificationStatus: VerificationStatus.PENDING,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
            createdAt: true,
          },
        },
      },
      orderBy: {
        user: {
          createdAt: 'asc',
        },
      },
    });

    return pendingPractitioners.map((p) => ({
      userId: p.user.id,
      email: p.user.email,
      name: p.user.name,
      practiceName: p.practiceName,
      specialties: p.specialties,
      yearsOfPractice: p.yearsOfPractice,
      professionalBody: p.professionalBody,
      qualifications: p.qualifications,
      credentialFiles: p.credentialFiles,
      submittedAt: p.user.createdAt,
    }));
  }

  // Admin: Update verification status
  async updateVerificationStatus(
    practitionerId: string,
    status: VerificationStatus,
    adminNotes?: string,
  ) {
    const profile = await this.prisma.practitionerProfile.findUnique({
      where: { userId: practitionerId },
    });

    if (!profile) {
      throw new NotFoundException('Practitioner profile not found');
    }

    const updatedProfile = await this.prisma.practitionerProfile.update({
      where: { userId: practitionerId },
      data: {
        verificationStatus: status,
        verifiedAt: status === VerificationStatus.VERIFIED ? new Date() : null,
      },
    });

    return {
      success: true,
      practitionerId,
      verificationStatus: updatedProfile.verificationStatus,
      verifiedAt: updatedProfile.verifiedAt,
    };
  }
}
