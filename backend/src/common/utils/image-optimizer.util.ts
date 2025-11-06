import { Logger } from '@nestjs/common';
import * as sharp from 'sharp';
import * as path from 'path';

/**
 * Image Optimization Utility
 *
 * Provides image compression, resizing, and format conversion.
 * Uses sharp library for high-performance image processing.
 *
 * Install: npm install sharp
 *
 * Usage:
 * const optimized = await ImageOptimizer.optimize(buffer, {
 *   maxWidth: 1200,
 *   quality: 80,
 * });
 *
 * const thumbnail = await ImageOptimizer.createThumbnail(buffer, 200);
 */
export class ImageOptimizer {
  private static readonly logger = new Logger('ImageOptimizer');

  /**
   * Optimize image with compression and resizing
   */
  static async optimize(
    inputBuffer: Buffer,
    options: {
      maxWidth?: number;
      maxHeight?: number;
      quality?: number; // 1-100
      format?: 'jpeg' | 'png' | 'webp';
    } = {},
  ): Promise<Buffer> {
    const {
      maxWidth = 1920,
      maxHeight = 1920,
      quality = 85,
      format = 'jpeg',
    } = options;

    try {
      const image = sharp(inputBuffer);
      const metadata = await image.metadata();

      this.logger.log(
        `Optimizing image: ${metadata.width}x${metadata.height} ${metadata.format}`,
      );

      // Resize if larger than max dimensions
      let processedImage = image;
      if (
        metadata.width &&
        metadata.height &&
        (metadata.width > maxWidth || metadata.height > maxHeight)
      ) {
        processedImage = image.resize(maxWidth, maxHeight, {
          fit: 'inside',
          withoutEnlargement: true,
        });
      }

      // Convert and compress
      let output: sharp.Sharp;
      switch (format) {
        case 'webp':
          output = processedImage.webp({ quality });
          break;
        case 'png':
          output = processedImage.png({
            quality,
            compressionLevel: 9,
          });
          break;
        case 'jpeg':
        default:
          output = processedImage.jpeg({
            quality,
            mozjpeg: true, // Use mozjpeg for better compression
          });
      }

      const outputBuffer = await output.toBuffer();

      const compressionRatio = (
        (1 - outputBuffer.length / inputBuffer.length) *
        100
      ).toFixed(2);

      this.logger.log(
        `Image optimized: ${inputBuffer.length}B → ${outputBuffer.length}B (${compressionRatio}% reduction)`,
      );

      return outputBuffer;
    } catch (error) {
      this.logger.error('Image optimization failed:', error);
      throw new Error('Failed to optimize image');
    }
  }

  /**
   * Create thumbnail from image
   */
  static async createThumbnail(
    inputBuffer: Buffer,
    size: number = 200,
  ): Promise<Buffer> {
    try {
      return await sharp(inputBuffer)
        .resize(size, size, {
          fit: 'cover',
          position: 'center',
        })
        .jpeg({ quality: 80, mozjpeg: true })
        .toBuffer();
    } catch (error) {
      this.logger.error('Thumbnail creation failed:', error);
      throw new Error('Failed to create thumbnail');
    }
  }

  /**
   * Create multiple sizes (responsive images)
   */
  static async createResponsiveSizes(
    inputBuffer: Buffer,
    sizes: number[] = [320, 640, 1024, 1920],
  ): Promise<{ size: number; buffer: Buffer }[]> {
    const results: { size: number; buffer: Buffer }[] = [];

    for (const size of sizes) {
      try {
        const buffer = await sharp(inputBuffer)
          .resize(size, null, {
            withoutEnlargement: true,
          })
          .jpeg({ quality: 85, mozjpeg: true })
          .toBuffer();

        results.push({ size, buffer });
      } catch (error) {
        this.logger.error(`Failed to create ${size}px version:`, error);
      }
    }

    return results;
  }

  /**
   * Get image metadata
   */
  static async getMetadata(
    inputBuffer: Buffer,
  ): Promise<sharp.Metadata> {
    return await sharp(inputBuffer).metadata();
  }

  /**
   * Validate image file
   */
  static async validateImage(
    inputBuffer: Buffer,
  ): Promise<{
    valid: boolean;
    error?: string;
    metadata?: sharp.Metadata;
  }> {
    try {
      const metadata = await this.getMetadata(inputBuffer);

      // Check file type
      if (!['jpeg', 'png', 'webp', 'gif'].includes(metadata.format || '')) {
        return {
          valid: false,
          error: `Unsupported format: ${metadata.format}`,
        };
      }

      // Check dimensions (max 10000x10000)
      if (
        metadata.width &&
        metadata.height &&
        (metadata.width > 10000 || metadata.height > 10000)
      ) {
        return {
          valid: false,
          error: 'Image dimensions too large (max 10000x10000)',
        };
      }

      return { valid: true, metadata };
    } catch (error) {
      return {
        valid: false,
        error: 'Invalid image file',
      };
    }
  }

  /**
   * Calculate optimal dimensions maintaining aspect ratio
   */
  static calculateDimensions(
    originalWidth: number,
    originalHeight: number,
    maxWidth: number,
    maxHeight: number,
  ): { width: number; height: number } {
    const aspectRatio = originalWidth / originalHeight;

    let width = originalWidth;
    let height = originalHeight;

    if (width > maxWidth) {
      width = maxWidth;
      height = Math.round(width / aspectRatio);
    }

    if (height > maxHeight) {
      height = maxHeight;
      width = Math.round(height * aspectRatio);
    }

    return { width, height };
  }
}
