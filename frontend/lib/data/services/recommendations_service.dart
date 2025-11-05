import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/recommendation.dart';
import 'package:sana_app/data/services/api_service.dart';

class RecommendationsService {
  final ApiService _apiService;

  RecommendationsService(this._apiService);

  Future<List<Recommendation>> getAllRecommendations({String? category}) async {
    final response = await _apiService.get(
      '/recommendations',
      queryParameters: category != null ? {'category': category} : null,
    );

    final List<dynamic> recommendationsJson = response.data['data'];
    return recommendationsJson
        .map((json) => Recommendation.fromJson(json))
        .toList();
  }

  Future<List<Recommendation>> getPersonalizedRecommendations() async {
    final response = await _apiService.get('/recommendations/personalized');

    final List<dynamic> recommendationsJson = response.data['data'];
    return recommendationsJson
        .map((json) => Recommendation.fromJson(json))
        .toList();
  }

  Future<Recommendation> getRecommendationBySlug(String slug) async {
    final response = await _apiService.get('/recommendations/$slug');

    return Recommendation.fromJson(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _apiService.get('/recommendations/categories');

    return List<Map<String, dynamic>>.from(response.data['data']);
  }
}

// Provider for RecommendationsService
final recommendationsServiceProvider = Provider<RecommendationsService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RecommendationsService(apiService);
});
