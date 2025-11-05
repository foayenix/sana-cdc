import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/data/models/recommendation.dart';
import 'package:sana_app/data/services/recommendations_service.dart';

final recommendationsProvider =
    FutureProvider.autoDispose<List<Recommendation>>((ref) async {
  final service = ref.watch(recommendationsServiceProvider);
  return await service.getPersonalizedRecommendations();
});

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
      ),
      body: recommendationsAsync.when(
        data: (recommendations) {
          if (recommendations.isEmpty) {
            return const Center(
              child: Text('No recommendations available yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recommendationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(rec.category[0]),
                    ),
                    title: Text(rec.title),
                    subtitle: Text(rec.category),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecommendationDetailScreen(slug: rec.slug),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(recommendationsProvider);
          },
        ),
      ),
    );
  }
}

class RecommendationDetailScreen extends ConsumerWidget {
  final String slug;

  const RecommendationDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation'),
      ),
      body: FutureBuilder<Recommendation>(
        future: ref.read(recommendationsServiceProvider).getRecommendationBySlug(slug),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(message: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Recommendation not found'));
          }

          final rec = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(rec.category)),
                const SizedBox(height: 12),
                Text(
                  rec.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Text(rec.content),
                const SizedBox(height: 24),
                if (rec.citations.isNotEmpty) ...[
                  Text(
                    'References',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...rec.citations.map((citation) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('• ${citation.title}'),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
