import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class UploadsService {
  private s3Client: S3Client;
  private bucketName: string;

  constructor(private readonly configService: ConfigService) {
    // Initialize S3 client (works with both AWS S3 and Cloudflare R2)
    this.s3Client = new S3Client({
      region: this.configService.get('AWS_REGION') || 'auto',
      credentials: {
        accessKeyId: this.configService.get('AWS_ACCESS_KEY_ID') || '',
        secretAccessKey: this.configService.get('AWS_SECRET_ACCESS_KEY') || '',
      },
      endpoint: this.configService.get('AWS_ENDPOINT'), // For Cloudflare R2
    });

    this.bucketName = this.configService.get('AWS_S3_BUCKET') || 'sana-uploads';
  }

  /**
   * Upload file to S3/R2
   */
  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'general',
  ): Promise<string> {
    // Validate file
    this.validateFile(file);

    // Generate unique filename
    const fileExtension = file.originalname.split('.').pop();
    const fileName = `${folder}/${uuidv4()}.${fileExtension}`;

    // Upload to S3
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: fileName,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'private', // Files are private by default
    });

    await this.s3Client.send(command);

    // Return the file URL/key
    return fileName;
  }

  /**
   * Upload multiple files
   */
  async uploadMultipleFiles(
    files: Express.Multer.File[],
    folder: string = 'general',
  ): Promise<string[]> {
    const uploadPromises = files.map((file) => this.uploadFile(file, folder));
    return await Promise.all(uploadPromises);
  }

  /**
   * Delete file from S3/R2
   */
  async deleteFile(fileKey: string): Promise<void> {
    const command = new DeleteObjectCommand({
      Bucket: this.bucketName,
      Key: fileKey,
    });

    await this.s3Client.send(command);
  }

  /**
   * Delete multiple files
   */
  async deleteMultipleFiles(fileKeys: string[]): Promise<void> {
    const deletePromises = fileKeys.map((key) => this.deleteFile(key));
    await Promise.all(deletePromises);
  }

  /**
   * Get signed URL for private file access
   */
  async getSignedUrl(fileKey: string, expiresIn: number = 3600): Promise<string> {
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: fileKey,
    });

    return await getSignedUrl(this.s3Client, command, { expiresIn });
  }

  /**
   * Validate file (size, type)
   */
  private validateFile(file: Express.Multer.File): void {
    const maxSize = 10 * 1024 * 1024; // 10MB
    const allowedTypes = [
      'image/jpeg',
      'image/png',
      'image/jpg',
      'application/pdf',
    ];

    if (file.size > maxSize) {
      throw new BadRequestException('File size exceeds 10MB limit');
    }

    if (!allowedTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        'Invalid file type. Only JPG, PNG, and PDF allowed',
      );
    }
  }

  /**
   * Get public URL for file
   */
  getPublicUrl(fileKey: string): string {
    const endpoint = this.configService.get('AWS_ENDPOINT');
    if (endpoint) {
      // Cloudflare R2 public URL
      return `${endpoint}/${this.bucketName}/${fileKey}`;
    }
    // AWS S3 public URL
    const region = this.configService.get('AWS_REGION');
    return `https://${this.bucketName}.s3.${region}.amazonaws.com/${fileKey}`;
  }
}
