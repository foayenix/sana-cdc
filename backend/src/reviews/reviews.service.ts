import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType, AppointmentStatus } from '@prisma/client';

interface CreateReviewDto {
  appointmentId: string;
  rating: number;
  title?: string;
  comment?: string;
}

interface ReplyToReviewDto {
  reviewId: string;
  reply: string;
}

@Injectable()
export class ReviewsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // Create a review for an appointment
  async createReview(clientId: string, createDto: CreateReviewDto) {
    const { appointmentId, rating, title, comment } = createDto;

    // Validate rating
    if (rating < 1 || rating > 5) {
      throw new BadRequestException('Rating must be between 1 and 5');
    }

    // Get appointment
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        review: true,
        practitioner: {
          include: {
            user: true,
          },
        },
        sessionType: true,
      },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Verify client owns this appointment
    if (appointment.clientId !== clientId) {
      throw new ForbiddenException('You can only review your own appointments');
    }

    // Check appointment is completed
    if (appointment.status !== AppointmentStatus.COMPLETED) {
      throw new BadRequestException(
        'You can only review completed appointments',
      );
    }

    // Check if review already exists
    if (appointment.review) {
      throw new BadRequestException(
        'You have already reviewed this appointment',
      );
    }

    // Create review
    const review = await this.prisma.review.create({
      data: {
        practitionerId: appointment.practitionerId,
        clientId,
        appointmentId,
        rating,
        title,
        comment,
        isPublished: true,
      },
      include: {
        client: {
          include: {
            user: true,
          },
        },
      },
    });

    // Send notification to practitioner
    try {
      await this.notificationsService.sendNotification({
        userId: appointment.practitionerId,
        type: NotificationType.REVIEW_RECEIVED,
        title: 'New Review Received',
        message: rating + ' stars - ' + review.client.user.name + ' reviewed your ' + appointment.sessionType.name + ' session.',
        data: {
          reviewId: review.id,
          appointmentId: appointment.id,
          rating,
        },
        sendEmail: true,
        sendPush: true,
      });
    } catch (error) {
      console.error('Failed to send review notification:', error);
    }

    return review;
  }

  // Get reviews for a practitioner
  async getPractitionerReviews(
    practitionerId: string,
    options?: {
      limit?: number;
      offset?: number;
      includeUnpublished?: boolean;
    },
  ) {
    const { limit = 20, offset = 0, includeUnpublished = false } = options || {};

    const where: any = {
      practitionerId,
    };

    if (!includeUnpublished) {
      where.isPublished = true;
    }

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where,
        include: {
          client: {
            include: {
              user: {
                select: {
                  name: true,
                  profilePhoto: true,
                },
              },
            },
          },
          appointment: {
            select: {
              sessionType: {
                select: {
                  name: true,
                },
              },
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
        take: limit,
        skip: offset,
      }),
      this.prisma.review.count({ where }),
    ]);

    // Calculate average rating
    const allReviews = await this.prisma.review.findMany({
      where: {
        practitionerId,
        isPublished: true,
      },
      select: {
        rating: true,
      },
    });

    const averageRating =
      allReviews.length > 0
        ? allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length
        : 0;

    // Calculate rating distribution
    const ratingDistribution = [0, 0, 0, 0, 0];
    allReviews.forEach((r) => {
      ratingDistribution[r.rating - 1]++;
    });

    return {
      reviews,
      total,
      averageRating: Math.round(averageRating * 10) / 10,
      totalReviews: allReviews.length,
      ratingDistribution: {
        5: ratingDistribution[4],
        4: ratingDistribution[3],
        3: ratingDistribution[2],
        2: ratingDistribution[1],
        1: ratingDistribution[0],
      },
    };
  }

  // Get a single review by ID
  async getReviewById(reviewId: string) {
    const review = await this.prisma.review.findUnique({
      where: { id: reviewId },
      include: {
        client: {
          include: {
            user: {
              select: {
                name: true,
                profilePhoto: true,
              },
            },
          },
        },
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
              },
            },
          },
        },
        appointment: {
          select: {
            sessionType: {
              select: {
                name: true,
              },
            },
          },
        },
      },
    });

    if (!review) {
      throw new NotFoundException('Review not found');
    }

    return review;
  }

  // Reply to a review (practitioner only)
  async replyToReview(practitionerId: string, replyDto: ReplyToReviewDto) {
    const { reviewId, reply } = replyDto;

    const review = await this.prisma.review.findUnique({
      where: { id: reviewId },
    });

    if (!review) {
      throw new NotFoundException('Review not found');
    }

    // Verify practitioner owns this review
    if (review.practitionerId !== practitionerId) {
      throw new ForbiddenException('You can only reply to your own reviews');
    }

    // Update review with reply
    const updatedReview = await this.prisma.review.update({
      where: { id: reviewId },
      data: {
        practitionerReply: reply,
        repliedAt: new Date(),
      },
      include: {
        client: {
          include: {
            user: true,
          },
        },
      },
    });

    return updatedReview;
  }

  // Toggle review visibility (practitioner or admin)
  async toggleReviewVisibility(
    userId: string,
    reviewId: string,
    isPublished: boolean,
  ) {
    const review = await this.prisma.review.findUnique({
      where: { id: reviewId },
    });

    if (!review) {
      throw new NotFoundException('Review not found');
    }

    // Verify practitioner owns this review (or is admin - TODO: add admin check)
    if (review.practitionerId !== userId) {
      throw new ForbiddenException(
        'You can only manage visibility of your own reviews',
      );
    }

    const updatedReview = await this.prisma.review.update({
      where: { id: reviewId },
      data: { isPublished },
    });

    return updatedReview;
  }

  // Get client's reviews
  async getClientReviews(clientId: string) {
    const reviews = await this.prisma.review.findMany({
      where: { clientId },
      include: {
        practitioner: {
          include: {
            user: {
              select: {
                name: true,
                profilePhoto: true,
              },
            },
          },
        },
        appointment: {
          select: {
            sessionType: {
              select: {
                name: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return reviews;
  }

  // Check if client can review an appointment
  async canReviewAppointment(clientId: string, appointmentId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        review: true,
      },
    });

    if (!appointment) {
      return { canReview: false, reason: 'Appointment not found' };
    }

    if (appointment.clientId !== clientId) {
      return { canReview: false, reason: 'Not your appointment' };
    }

    if (appointment.status !== AppointmentStatus.COMPLETED) {
      return { canReview: false, reason: 'Appointment not completed yet' };
    }

    if (appointment.review) {
      return { canReview: false, reason: 'Already reviewed' };
    }

    return { canReview: true };
  }
}
