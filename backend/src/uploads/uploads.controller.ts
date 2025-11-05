import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFile,
  UploadedFiles,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { UploadsService } from './uploads.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  /**
   * POST /api/uploads/single
   * Upload a single file
   */
  @Post('single')
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    const fileKey = await this.uploadsService.uploadFile(file, 'general');

    return {
      success: true,
      data: {
        fileKey,
        url: this.uploadsService.getPublicUrl(fileKey),
      },
    };
  }

  /**
   * POST /api/uploads/multiple
   * Upload multiple files (max 5)
   */
  @Post('multiple')
  @UseInterceptors(FilesInterceptor('files', 5))
  async uploadMultipleFiles(@UploadedFiles() files: Express.Multer.File[]) {
    if (!files || files.length === 0) {
      throw new BadRequestException('No files provided');
    }

    if (files.length > 5) {
      throw new BadRequestException('Maximum 5 files allowed');
    }

    const fileKeys = await this.uploadsService.uploadMultipleFiles(
      files,
      'credentials',
    );

    return {
      success: true,
      data: {
        fileKeys,
        urls: fileKeys.map((key) => this.uploadsService.getPublicUrl(key)),
      },
    };
  }

  /**
   * POST /api/uploads/profile-photo
   * Upload profile photo
   */
  @Post('profile-photo')
  @UseInterceptors(FileInterceptor('photo'))
  async uploadProfilePhoto(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No photo provided');
    }

    // Validate it's an image
    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('Only image files allowed');
    }

    const fileKey = await this.uploadsService.uploadFile(file, 'profile-photos');

    return {
      success: true,
      data: {
        fileKey,
        url: this.uploadsService.getPublicUrl(fileKey),
      },
    };
  }
}
