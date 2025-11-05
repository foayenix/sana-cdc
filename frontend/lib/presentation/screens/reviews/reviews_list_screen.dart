import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/data/models/review.dart';
import 'package:sana_app/data/services/reviews_service.dart';

class ReviewsListScreen extends ConsumerWidget {
  final String practitionerId;
  final String practitionerName;

  const ReviewsListScreen({
    super.key,
    required this.practitionerId,
    required this.practitionerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(
      practitionerReviewsNotifierProvider(practitionerId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(practitionerName + ' Reviews'),
      ),
      body: reviewsAsync.when(
        data: (response) => _buildReviewsList(context, ref, response),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(practitionerReviewsNotifierProvider(practitionerId)
                          .notifier)
                      .loadReviews(refresh: true);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList(
    BuildContext context,
    WidgetRef ref,
    PractitionerReviewsResponse response,
  ) {
    if (response.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to leave a review',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(practitionerReviewsNotifierProvider(practitionerId).notifier)
            .loadReviews(refresh: true);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rating summary card
          _buildRatingSummary(context, response),
          const SizedBox(height: 24),

          // Reviews list
          ...response.reviews.map((review) => _buildReviewCard(review)),

          // Load more button
          if (response.reviews.length < response.total)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(practitionerReviewsNotifierProvider(
                                practitionerId)
                            .notifier)
                        .loadMore();
                  },
                  child: const Text('Load More'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(
    BuildContext context,
    PractitionerReviewsResponse response,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Average rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  response.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarRating(response.averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '${response.totalReviews} reviews',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Rating distribution
            _buildRatingBar(5, response.ratingDistribution.five, response.totalReviews),
            _buildRatingBar(4, response.ratingDistribution.four, response.totalReviews),
            _buildRatingBar(3, response.ratingDistribution.three, response.totalReviews),
            _buildRatingBar(2, response.ratingDistribution.two, response.totalReviews),
            _buildRatingBar(1, response.ratingDistribution.one, response.totalReviews),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            stars.toString(),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        if (rating >= starValue) {
          return const Icon(Icons.star, size: 20, color: Colors.amber);
        } else if (rating >= starValue - 0.5) {
          return const Icon(Icons.star_half, size: 20, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: 20, color: Colors.grey[400]);
        }
      }),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user and rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  backgroundImage: review.client?.user.profilePhoto != null
                      ? NetworkImage(review.client!.user.profilePhoto!)
                      : null,
                  child: review.client?.user.profilePhoto == null
                      ? Text(
                          review.client?.user.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.client?.user.name ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy').format(review.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(review.rating.toDouble()),
              ],
            ),
            const SizedBox(height: 12),

            // Session type badge
            if (review.appointment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  review.appointment!.sessionType.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Review title
            if (review.title != null && review.title!.isNotEmpty) ...[
              Text(
                review.title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Review comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],

            // Practitioner reply
            if (review.practitionerReply != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Practitioner Response',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (review.repliedAt != null)
                          Text(
                            DateFormat('MMM dd').format(review.repliedAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.practitionerReply!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
