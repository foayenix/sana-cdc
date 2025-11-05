import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/review.dart';
import 'package:sana_app/core/network/dio_client.dart';

/// Reviews service for API communication
class ReviewsService {
  final Dio _dio;

  ReviewsService(this._dio);

  /// Create a review for an appointment
  Future<Review> createReview(CreateReviewRequest request) async {
    try {
      final response = await _dio.post(
        '/reviews',
        data: request.toJson(),
      );
      return Review.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get reviews for a practitioner
  Future<PractitionerReviewsResponse> getPractitionerReviews(
    String practitionerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/reviews/practitioner/$practitionerId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return PractitionerReviewsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single review by ID
  Future<Review> getReview(String reviewId) async {
    try {
      final response = await _dio.get('/reviews/$reviewId');
      return Review.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reply to a review (practitioner only)
  Future<Review> replyToReview(String reviewId, String reply) async {
    try {
      final response = await _dio.put(
        '/reviews/$reviewId/reply',
        data: {'reply': reply},
      );
      return Review.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Toggle review visibility
  Future<Review> toggleReviewVisibility(
    String reviewId,
    bool isPublished,
  ) async {
    try {
      final response = await _dio.put(
        '/reviews/$reviewId/visibility',
        data: {'isPublished': isPublished},
      );
      return Review.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user's reviews
  Future<List<Review>> getMyReviews() async {
    try {
      final response = await _dio.get('/reviews/my/reviews');
      return (response.data as List)
          .map((json) => Review.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check if can review an appointment
  Future<CanReviewResponse> canReviewAppointment(String appointmentId) async {
    try {
      final response = await _dio.get('/reviews/can-review/$appointmentId');
      return CanReviewResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Provider for ReviewsService
final reviewsServiceProvider = Provider<ReviewsService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ReviewsService(dio);
});

/// Provider for practitioner reviews
final practitionerReviewsProvider = FutureProvider.family<
    PractitionerReviewsResponse,
    ({String practitionerId, int offset})>((ref, params) async {
  final service = ref.watch(reviewsServiceProvider);
  return service.getPractitionerReviews(
    params.practitionerId,
    limit: 20,
    offset: params.offset,
  );
});

/// Provider for my reviews
final myReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final service = ref.watch(reviewsServiceProvider);
  return service.getMyReviews();
});

/// Provider for can review check
final canReviewProvider =
    FutureProvider.family<CanReviewResponse, String>((ref, appointmentId) async {
  final service = ref.watch(reviewsServiceProvider);
  return service.canReviewAppointment(appointmentId);
});

/// State notifier for managing practitioner reviews
class PractitionerReviewsNotifier
    extends StateNotifier<AsyncValue<PractitionerReviewsResponse>> {
  final ReviewsService _service;
  final String practitionerId;
  int _currentOffset = 0;

  PractitionerReviewsNotifier(this._service, this.practitionerId)
      : super(const AsyncValue.loading()) {
    loadReviews();
  }

  /// Load reviews
  Future<void> loadReviews({bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      state = const AsyncValue.loading();
    }

    try {
      final result = await _service.getPractitionerReviews(
        practitionerId,
        limit: 20,
        offset: _currentOffset,
      );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load more reviews
  Future<void> loadMore() async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final currentData = currentState.value!;
    if (currentData.reviews.length >= currentData.total) return;

    _currentOffset += 20;

    try {
      final result = await _service.getPractitionerReviews(
        practitionerId,
        limit: 20,
        offset: _currentOffset,
      );

      state = AsyncValue.data(
        PractitionerReviewsResponse(
          reviews: [...currentData.reviews, ...result.reviews],
          total: result.total,
          averageRating: result.averageRating,
          totalReviews: result.totalReviews,
          ratingDistribution: result.ratingDistribution,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for practitioner reviews notifier
final practitionerReviewsNotifierProvider = StateNotifierProvider.family<
    PractitionerReviewsNotifier,
    AsyncValue<PractitionerReviewsResponse>,
    String>((ref, practitionerId) {
  final service = ref.watch(reviewsServiceProvider);
  return PractitionerReviewsNotifier(service, practitionerId);
});
