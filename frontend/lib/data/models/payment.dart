import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

enum PaymentStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('FAILED')
  failed,
  @JsonValue('REFUNDED')
  refunded,
}

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String appointmentId,
    required double amount,
    required String currency,
    required PaymentStatus status,
    required String stripePaymentIntentId,
    String? stripeClientSecret,
    DateTime? paidAt,
    DateTime? refundedAt,
    required DateTime createdAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}

@freezed
class PaymentIntentResponse with _$PaymentIntentResponse {
  const factory PaymentIntentResponse({
    required String clientSecret,
    required String paymentId,
    required double amount,
  }) = _PaymentIntentResponse;

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentResponseFromJson(json);
}
