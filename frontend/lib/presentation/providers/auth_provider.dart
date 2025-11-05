import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/config/app_config.dart';
import 'package:sana_app/data/models/user.dart';
import 'package:sana_app/data/services/auth_service.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await AppConfig.getAccessToken();
    if (token != null) {
      try {
        final user = await _authService.getCurrentUser();
        state = AuthState(user: user, isAuthenticated: true);
      } catch (e) {
        await AppConfig.clearUserData();
        state = const AuthState();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      await AppConfig.setAccessToken(response.data.accessToken);
      await AppConfig.setRefreshToken(response.data.refreshToken);
      await AppConfig.setUserId(response.data.user.id);
      await AppConfig.setUserRole(response.data.user.role.toString());

      state = AuthState(
        user: response.data.user,
        isAuthenticated: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      await AppConfig.setAccessToken(response.data.accessToken);
      await AppConfig.setRefreshToken(response.data.refreshToken);
      await AppConfig.setUserId(response.data.user.id);
      await AppConfig.setUserRole(response.data.user.role.toString());

      state = AuthState(
        user: response.data.user,
        isAuthenticated: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }

    await AppConfig.clearUserData();
    state = const AuthState();
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = state.copyWith(user: user);
    } catch (e) {
      // Handle error silently
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
