import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin.dart';
import '../../core/constants/api_constants.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

class AdminService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  // Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Platform Stats
  Future<PlatformStats> getPlatformStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      return PlatformStats.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // User Management
  Future<GetUsersResponse> getUsers({
    String? role,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (role != null) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '/admin/users',
        queryParameters: queryParams,
      );
      return GetUsersResponse.fromJson({
        'users': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AdminUser> getUserById(String userId) async {
    try {
      final response = await _dio.get('/admin/users/$userId');
      return AdminUser.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserActivityStats> getUserActivityStats(String userId) async {
    try {
      final response = await _dio.get('/admin/users/$userId/activity');
      return UserActivityStats.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Practitioner Verification
  Future<GetPendingVerificationsResponse> getPendingVerifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/verifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return GetPendingVerificationsResponse.fromJson({
        'practitioners': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateVerificationStatus({
    required String practitionerId,
    required String status,
    required String adminId,
  }) async {
    try {
      await _dio.put(
        '/admin/verifications/$practitionerId/status',
        data: {
          'status': status,
          'adminId': adminId,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Review Management
  Future<GetReviewsResponse> getRecentReviews({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/reviews',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return GetReviewsResponse.fromJson({
        'reviews': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateReviewStatus({
    required String reviewId,
    required bool isPublished,
  }) async {
    try {
      await _dio.put(
        '/admin/reviews/$reviewId/status',
        data: {'isPublished': isPublished},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Appointment Management
  Future<GetAppointmentsResponse> getRecentAppointments({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/appointments',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return GetAppointmentsResponse.fromJson({
        'appointments': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        return e.response?.data['message'] ?? 'An error occurred';
      }
      return 'Network error. Please check your connection.';
    }
    return 'An unexpected error occurred';
  }
}

// State Management with Riverpod

// Platform Stats State
class PlatformStatsState {
  final PlatformStats? stats;
  final bool isLoading;
  final String? error;

  PlatformStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  PlatformStatsState copyWith({
    PlatformStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return PlatformStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PlatformStatsNotifier extends StateNotifier<PlatformStatsState> {
  final AdminService _adminService;

  PlatformStatsNotifier(this._adminService) : super(PlatformStatsState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _adminService.getPlatformStats();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => loadStats();
}

final platformStatsProvider =
    StateNotifierProvider<PlatformStatsNotifier, PlatformStatsState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return PlatformStatsNotifier(adminService);
});

// Users State
class UsersState {
  final List<AdminUser> users;
  final int total;
  final bool isLoading;
  final String? error;
  final String? roleFilter;
  final String? searchQuery;

  UsersState({
    this.users = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.roleFilter,
    this.searchQuery,
  });

  UsersState copyWith({
    List<AdminUser>? users,
    int? total,
    bool? isLoading,
    String? error,
    String? roleFilter,
    String? searchQuery,
  }) {
    return UsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      roleFilter: roleFilter ?? this.roleFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  final AdminService _adminService;

  UsersNotifier(this._adminService) : super(UsersState());

  Future<void> loadUsers({
    String? role,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      roleFilter: role,
      searchQuery: search,
    );
    try {
      final response = await _adminService.getUsers(
        role: role,
        search: search,
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        users: offset == 0 ? response.users : [...state.users, ...response.users],
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => loadUsers(
        role: state.roleFilter,
        search: state.searchQuery,
      );
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return UsersNotifier(adminService);
});

// Pending Verifications State
class VerificationsState {
  final List<PendingPractitioner> practitioners;
  final int total;
  final bool isLoading;
  final String? error;

  VerificationsState({
    this.practitioners = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  VerificationsState copyWith({
    List<PendingPractitioner>? practitioners,
    int? total,
    bool? isLoading,
    String? error,
  }) {
    return VerificationsState(
      practitioners: practitioners ?? this.practitioners,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VerificationsNotifier extends StateNotifier<VerificationsState> {
  final AdminService _adminService;

  VerificationsNotifier(this._adminService) : super(VerificationsState());

  Future<void> loadVerifications({int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _adminService.getPendingVerifications(
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        practitioners: offset == 0
            ? response.practitioners
            : [...state.practitioners, ...response.practitioners],
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus({
    required String practitionerId,
    required String status,
    required String adminId,
  }) async {
    try {
      await _adminService.updateVerificationStatus(
        practitionerId: practitionerId,
        status: status,
        adminId: adminId,
      );
      // Remove from list after update
      state = state.copyWith(
        practitioners: state.practitioners
            .where((p) => p.id != practitionerId)
            .toList(),
        total: state.total - 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => loadVerifications();
}

final verificationsProvider =
    StateNotifierProvider<VerificationsNotifier, VerificationsState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return VerificationsNotifier(adminService);
});

// Reviews State
class ReviewsState {
  final List<AdminReview> reviews;
  final int total;
  final bool isLoading;
  final String? error;

  ReviewsState({
    this.reviews = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  ReviewsState copyWith({
    List<AdminReview>? reviews,
    int? total,
    bool? isLoading,
    String? error,
  }) {
    return ReviewsState(
      reviews: reviews ?? this.reviews,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReviewsNotifier extends StateNotifier<ReviewsState> {
  final AdminService _adminService;

  ReviewsNotifier(this._adminService) : super(ReviewsState());

  Future<void> loadReviews({int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _adminService.getRecentReviews(
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        reviews:
            offset == 0 ? response.reviews : [...state.reviews, ...response.reviews],
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus({
    required String reviewId,
    required bool isPublished,
  }) async {
    try {
      await _adminService.updateReviewStatus(
        reviewId: reviewId,
        isPublished: isPublished,
      );
      // Update in list
      state = state.copyWith(
        reviews: state.reviews.map((r) {
          if (r.id == reviewId) {
            return r.copyWith(isPublished: isPublished);
          }
          return r;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => loadReviews();
}

final reviewsProvider =
    StateNotifierProvider<ReviewsNotifier, ReviewsState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return ReviewsNotifier(adminService);
});

// Appointments State
class AppointmentsState {
  final List<AdminAppointment> appointments;
  final int total;
  final bool isLoading;
  final String? error;

  AppointmentsState({
    this.appointments = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  AppointmentsState copyWith({
    List<AdminAppointment>? appointments,
    int? total,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AdminService _adminService;

  AppointmentsNotifier(this._adminService) : super(AppointmentsState());

  Future<void> loadAppointments({int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _adminService.getRecentAppointments(
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        appointments: offset == 0
            ? response.appointments
            : [...state.appointments, ...response.appointments],
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => loadAppointments();
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AppointmentsNotifier(adminService);
});
