import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';
part 'review.g.dart';

/// Review model
@freezed
class Review with _$Review {
  const factory Review({
    required String id,
    required String practitionerId,
    required String clientId,
    required String appointmentId,
    required int rating,
    String? title,
    String? comment,
    @Default(true) bool isPublished,
    String? practitionerReply,
    DateTime? repliedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Nested relations
    ReviewClient? client,
    ReviewPractitioner? practitioner,
    ReviewAppointment? appointment,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}

/// Client info in review
@freezed
class ReviewClient with _$ReviewClient {
  const factory ReviewClient({
    required ReviewUser user,
  }) = _ReviewClient;

  factory ReviewClient.fromJson(Map<String, dynamic> json) =>
      _$ReviewClientFromJson(json);
}

/// Practitioner info in review
@freezed
class ReviewPractitioner with _$ReviewPractitioner {
  const factory ReviewPractitioner({
    required ReviewUser user,
  }) = _ReviewPractitioner;

  factory ReviewPractitioner.fromJson(Map<String, dynamic> json) =>
      _$ReviewPractitionerFromJson(json);
}

/// User info in review
@freezed
class ReviewUser with _$ReviewUser {
  const factory ReviewUser({
    required String name,
    String? profilePhoto,
  }) = _ReviewUser;

  factory ReviewUser.fromJson(Map<String, dynamic> json) =>
      _$ReviewUserFromJson(json);
}

/// Appointment info in review
@freezed
class ReviewAppointment with _$ReviewAppointment {
  const factory ReviewAppointment({
    required ReviewSessionType sessionType,
  }) = _ReviewAppointment;

  factory ReviewAppointment.fromJson(Map<String, dynamic> json) =>
      _$ReviewAppointmentFromJson(json);
}

/// Session type info in review
@freezed
class ReviewSessionType with _$ReviewSessionType {
  const factory ReviewSessionType({
    required String name,
  }) = _ReviewSessionType;

  factory ReviewSessionType.fromJson(Map<String, dynamic> json) =>
      _$ReviewSessionTypeFromJson(json);
}

/// Rating distribution
@freezed
class RatingDistribution with _$RatingDistribution {
  const factory RatingDistribution({
    @JsonKey(name: '5') required int five,
    @JsonKey(name: '4') required int four,
    @JsonKey(name: '3') required int three,
    @JsonKey(name: '2') required int two,
    @JsonKey(name: '1') required int one,
  }) = _RatingDistribution;

  factory RatingDistribution.fromJson(Map<String, dynamic> json) =>
      _$RatingDistributionFromJson(json);
}

/// Practitioner reviews response
@freezed
class PractitionerReviewsResponse with _$PractitionerReviewsResponse {
  const factory PractitionerReviewsResponse({
    required List<Review> reviews,
    required int total,
    required double averageRating,
    required int totalReviews,
    required RatingDistribution ratingDistribution,
  }) = _PractitionerReviewsResponse;

  factory PractitionerReviewsResponse.fromJson(Map<String, dynamic> json) =>
      _$PractitionerReviewsResponseFromJson(json);
}

/// Create review request
@freezed
class CreateReviewRequest with _$CreateReviewRequest {
  const factory CreateReviewRequest({
    required String appointmentId,
    required int rating,
    String? title,
    String? comment,
  }) = _CreateReviewRequest;

  factory CreateReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReviewRequestFromJson(json);
}

/// Reply to review request
@freezed
class ReplyToReviewRequest with _$ReplyToReviewRequest {
  const factory ReplyToReviewRequest({
    required String reply,
  }) = _ReplyToReviewRequest;

  factory ReplyToReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$ReplyToReviewRequestFromJson(json);
}

/// Can review response
@freezed
class CanReviewResponse with _$CanReviewResponse {
  const factory CanReviewResponse({
    required bool canReview,
    String? reason,
  }) = _CanReviewResponse;

  factory CanReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$CanReviewResponseFromJson(json);
}
