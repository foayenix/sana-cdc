import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/models/payment.dart';
import 'package:sana_app/data/services/api_service.dart';

class PaymentsService {
  final Dio dio;

  PaymentsService(this.dio);

  // Create payment intent for appointment
  Future<PaymentIntentResponse> createPaymentIntent({
    required String appointmentId,
  }) async {
    final response = await dio.post(
      '/payments/create-intent',
      data: {'appointmentId': appointmentId},
    );
    return PaymentIntentResponse.fromJson(response.data);
  }

  // Get all payments for authenticated user
  Future<List<Payment>> getPayments() async {
    final response = await dio.get('/payments');
    final List<dynamic> data = response.data ?? [];
    return data.map((payment) => Payment.fromJson(payment)).toList();
  }

  // Get payment by ID
  Future<Payment> getPaymentById(String paymentId) async {
    final response = await dio.get('/payments/$paymentId');
    return Payment.fromJson(response.data);
  }

  // Process refund (practitioner only)
  Future<Payment> refundPayment({
    required String paymentId,
    String? reason,
  }) async {
    final response = await dio.post(
      '/payments/$paymentId/refund',
      data: {
        if (reason != null) 'reason': reason,
      },
    );
    return Payment.fromJson(response.data);
  }
}

// Provider
final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  final dio = ref.watch(dioProvider);
  return PaymentsService(dio);
});
