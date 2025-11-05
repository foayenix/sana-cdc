import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/appointment.dart';
import 'package:sana_app/data/services/api_service.dart';

class AppointmentsService {
  final Dio dio;

  AppointmentsService(this.dio);

  // Create appointment (client books with practitioner)
  Future<Appointment> createAppointment({
    required String practitionerId,
    required String sessionTypeId,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    final response = await dio.post(
      '/appointments',
      data: {
        'practitionerId': practitionerId,
        'sessionTypeId': sessionTypeId,
        'appointmentDate': appointmentDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return Appointment.fromJson(response.data);
  }

  // Get all appointments for authenticated user
  Future<List<Appointment>> getAppointments({
    AppointmentStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) {
      queryParams['status'] = status.name.toUpperCase();
    }
    if (fromDate != null) {
      queryParams['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      queryParams['toDate'] = toDate.toIso8601String();
    }

    final response = await dio.get(
      '/appointments',
      queryParameters: queryParams,
    );
    final List<dynamic> data = response.data ?? [];
    return data.map((apt) => Appointment.fromJson(apt)).toList();
  }

  // Get single appointment by ID
  Future<Appointment> getAppointmentById(String appointmentId) async {
    final response = await dio.get('/appointments/$appointmentId');
    return Appointment.fromJson(response.data);
  }

  // Get available time slots for a practitioner on a specific date
  Future<List<AvailableTimeSlot>> getAvailableSlots({
    required String practitionerId,
    required DateTime date,
  }) async {
    final response = await dio.get(
      '/appointments/slots/$practitionerId',
      queryParameters: {
        'date': date.toIso8601String(),
      },
    );
    final List<dynamic> data = response.data ?? [];
    return data.map((slot) => AvailableTimeSlot.fromJson(slot)).toList();
  }

  // Update appointment (reschedule or change notes)
  Future<Appointment> updateAppointment({
    required String appointmentId,
    DateTime? appointmentDate,
    AppointmentStatus? status,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{};
    if (appointmentDate != null) {
      updateData['appointmentDate'] = appointmentDate.toIso8601String();
    }
    if (status != null) {
      updateData['status'] = status.name.toUpperCase();
    }
    if (notes != null) {
      updateData['notes'] = notes;
    }

    final response = await dio.put(
      '/appointments/$appointmentId',
      data: updateData,
    );
    return Appointment.fromJson(response.data);
  }

  // Cancel appointment
  Future<Appointment> cancelAppointment({
    required String appointmentId,
    String? reason,
  }) async {
    final response = await dio.delete(
      '/appointments/$appointmentId',
      data: {
        if (reason != null) 'reason': reason,
      },
    );
    return Appointment.fromJson(response.data);
  }

  // Confirm appointment (practitioner only)
  Future<Appointment> confirmAppointment(String appointmentId) async {
    final response = await dio.post('/appointments/$appointmentId/confirm');
    return Appointment.fromJson(response.data);
  }

  // Complete appointment (practitioner only)
  Future<Appointment> completeAppointment(String appointmentId) async {
    final response = await dio.post('/appointments/$appointmentId/complete');
    return Appointment.fromJson(response.data);
  }
}

// Provider
final appointmentsServiceProvider = Provider<AppointmentsService>((ref) {
  final dio = ref.watch(dioProvider);
  return AppointmentsService(dio);
});
