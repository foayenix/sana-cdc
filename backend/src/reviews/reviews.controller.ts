import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ParseIntPipe,
  DefaultValuePipe,
  ParseBoolPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ReviewsService } from './reviews.service';

@Controller('reviews')
@UseGuards(JwtAuthGuard)
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  // Create a review
  @Post()
  async createReview(@Request() req, @Body() createDto: any) {
    const clientId = req.user.userId;
    return await this.reviewsService.createReview(clientId, createDto);
  }

  // Get reviews for a practitioner
  @Get('practitioner/:practitionerId')
  async getPractitionerReviews(
    @Param('practitionerId') practitionerId: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset: number,
  ) {
    return await this.reviewsService.getPractitionerReviews(practitionerId, {
      limit,
      offset,
      includeUnpublished: false,
    });
  }

  // Get a single review
  @Get(':id')
  async getReview(@Param('id') reviewId: string) {
    return await this.reviewsService.getReviewById(reviewId);
  }

  // Reply to a review (practitioner only)
  @Put(':id/reply')
  async replyToReview(
    @Request() req,
    @Param('id') reviewId: string,
    @Body('reply') reply: string,
  ) {
    const practitionerId = req.user.userId;
    return await this.reviewsService.replyToReview(practitionerId, {
      reviewId,
      reply,
    });
  }

  // Toggle review visibility
  @Put(':id/visibility')
  async toggleVisibility(
    @Request() req,
    @Param('id') reviewId: string,
    @Body('isPublished', ParseBoolPipe) isPublished: boolean,
  ) {
    const userId = req.user.userId;
    return await this.reviewsService.toggleReviewVisibility(
      userId,
      reviewId,
      isPublished,
    );
  }

  // Get client's reviews
  @Get('my/reviews')
  async getMyReviews(@Request() req) {
    const clientId = req.user.userId;
    return await this.reviewsService.getClientReviews(clientId);
  }

  // Check if can review appointment
  @Get('can-review/:appointmentId')
  async canReview(
    @Request() req,
    @Param('appointmentId') appointmentId: string,
  ) {
    const clientId = req.user.userId;
    return await this.reviewsService.canReviewAppointment(
      clientId,
      appointmentId,
    );
  }
}
