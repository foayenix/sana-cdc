import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/auth_response.dart';
import 'package:sana_app/data/models/user.dart';
import 'package:sana_app/data/services/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final response = await _apiService.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'name': name,
        'role': role == UserRole.client ? 'CLIENT' : 'PRACTITIONER',
      },
    );

    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> googleAuth({
    required String googleId,
    required String email,
    required String name,
    required UserRole role,
    String? profilePhoto,
  }) async {
    final response = await _apiService.post(
      '/auth/google',
      data: {
        'googleId': googleId,
        'email': email,
        'name': name,
        'role': role == UserRole.client ? 'CLIENT' : 'PRACTITIONER',
        'profilePhoto': profilePhoto,
      },
    );

    return AuthResponse.fromJson(response.data);
  }

  Future<User> getCurrentUser() async {
    final response = await _apiService.get('/auth/me');
    return User.fromJson(response.data['data']);
  }

  Future<void> logout() async {
    await _apiService.post('/auth/logout');
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
});
