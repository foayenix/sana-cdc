import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/availability.dart';
import 'api_service.dart';

final availabilityServiceProvider = Provider<AvailabilityService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AvailabilityService(apiService);
});

class AvailabilityService {
  final ApiService _apiService;

  AvailabilityService(this._apiService);

  Future<AvailabilitySlot> createAvailabilitySlot(CreateAvailabilitySlotRequest request) async {
    try {
      final response = await _apiService.dio.post('/availability/slots', data: request.toJson());
      return AvailabilitySlot.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create availability slot');
    }
  }

  Future<List<AvailabilitySlot>> getAvailabilitySlots(String practitionerId, {bool activeOnly = true}) async {
    try {
      final response = await _apiService.dio.get('/availability/slots/' + practitionerId, queryParameters: {'activeOnly': activeOnly});
      return (response.data as List).map((json) => AvailabilitySlot.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load availability slots');
    }
  }

  Future<AvailabilitySlot> updateAvailabilitySlot(String slotId, UpdateAvailabilitySlotRequest request) async {
    try {
      final response = await _apiService.dio.put('/availability/slots/' + slotId, data: request.toJson());
      return AvailabilitySlot.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update availability slot');
    }
  }

  Future<void> deleteAvailabilitySlot(String slotId) async {
    try {
      await _apiService.dio.delete('/availability/slots/' + slotId);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete availability slot');
    }
  }

  Future<void> bulkCreateAvailabilitySlots(List<CreateAvailabilitySlotRequest> slots) async {
    try {
      await _apiService.dio.post('/availability/slots/bulk', data: {'slots': slots.map((s) => s.toJson()).toList()});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create availability slots');
    }
  }

  Future<TimeOff> createTimeOff(CreateTimeOffRequest request) async {
    try {
      final response = await _apiService.dio.post('/availability/time-off', data: request.toJson());
      return TimeOff.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to request time off');
    }
  }

  Future<List<TimeOff>> getTimeOffs(String practitionerId, {TimeOffStatus? status}) async {
    try {
      final response = await _apiService.dio.get('/availability/time-off/' + practitionerId, queryParameters: status != null ? {'status': status.name.toUpperCase()} : null);
      return (response.data as List).map((json) => TimeOff.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load time off requests');
    }
  }

  Future<TimeOff> updateTimeOffStatus(String timeOffId, TimeOffStatus status) async {
    try {
      final response = await _apiService.dio.put('/availability/time-off/' + timeOffId + '/status', data: {'status': status.name.toUpperCase()});
      return TimeOff.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update time off status');
    }
  }

  Future<AvailabilityOverride> createAvailabilityOverride(CreateAvailabilityOverrideRequest request) async {
    try {
      final response = await _apiService.dio.post('/availability/overrides', data: request.toJson());
      return AvailabilityOverride.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create availability override');
    }
  }

  Future<List<AvailabilityOverride>> getAvailabilityOverrides(String practitionerId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.dio.get('/availability/overrides/' + practitionerId, queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      return (response.data as List).map((json) => AvailabilityOverride.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load availability overrides');
    }
  }

  static String formatTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    if (hour == 0) {
      return '12:' + minute + ' AM';
    } else if (hour < 12) {
      return hour.toString() + ':' + minute + ' AM';
    } else if (hour == 12) {
      return '12:' + minute + ' PM';
    } else {
      return (hour - 12).toString() + ':' + minute + ' PM';
    }
  }

  static DateTime parseTimeToday(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

class AvailabilityState {
  final List<AvailabilitySlot> slots;
  final List<TimeOff> timeOffs;
  final List<AvailabilityOverride> overrides;
  final bool isLoading;
  final String? error;

  AvailabilityState({
    this.slots = const [],
    this.timeOffs = const [],
    this.overrides = const [],
    this.isLoading = false,
    this.error,
  });

  AvailabilityState copyWith({
    List<AvailabilitySlot>? slots,
    List<TimeOff>? timeOffs,
    List<AvailabilityOverride>? overrides,
    bool? isLoading,
    String? error,
  }) {
    return AvailabilityState(
      slots: slots ?? this.slots,
      timeOffs: timeOffs ?? this.timeOffs,
      overrides: overrides ?? this.overrides,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final AvailabilityService _availabilityService;
  final String practitionerId;

  AvailabilityNotifier(this._availabilityService, this.practitionerId) : super(AvailabilityState());

  Future<void> loadAvailability() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final slots = await _availabilityService.getAvailabilitySlots(practitionerId);
      final timeOffs = await _availabilityService.getTimeOffs(practitionerId);
      final now = DateTime.now();
      final threeMonthsLater = DateTime(now.year, now.month + 3, now.day);
      final overrides = await _availabilityService.getAvailabilityOverrides(practitionerId, now, threeMonthsLater);
      state = state.copyWith(slots: slots, timeOffs: timeOffs, overrides: overrides, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addSlot(CreateAvailabilitySlotRequest request) async {
    try {
      final slot = await _availabilityService.createAvailabilitySlot(request);
      state = state.copyWith(slots: [...state.slots, slot]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateSlot(String slotId, UpdateAvailabilitySlotRequest request) async {
    try {
      final updated = await _availabilityService.updateAvailabilitySlot(slotId, request);
      final updatedSlots = state.slots.map((s) => s.id == slotId ? updated : s).toList();
      state = state.copyWith(slots: updatedSlots);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteSlot(String slotId) async {
    try {
      await _availabilityService.deleteAvailabilitySlot(slotId);
      final updatedSlots = state.slots.where((s) => s.id != slotId).toList();
      state = state.copyWith(slots: updatedSlots);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> requestTimeOff(CreateTimeOffRequest request) async {
    try {
      final timeOff = await _availabilityService.createTimeOff(request);
      state = state.copyWith(timeOffs: [...state.timeOffs, timeOff]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> createOverride(CreateAvailabilityOverrideRequest request) async {
    try {
      final override = await _availabilityService.createAvailabilityOverride(request);
      state = state.copyWith(overrides: [...state.overrides, override]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final availabilityNotifierProvider = StateNotifierProvider.family<AvailabilityNotifier, AvailabilityState, String>(
  (ref, practitionerId) {
    final availabilityService = ref.watch(availabilityServiceProvider);
    return AvailabilityNotifier(availabilityService, practitionerId);
  },
);
