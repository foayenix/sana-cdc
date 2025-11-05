import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

// Payment Status Enum
enum PaymentStatus {
  PENDING,
  PROCESSING,
  COMPLETED,
  FAILED,
  REFUNDED,
  CANCELLED,
}

// Payment Method Enum
enum PaymentMethod {
  CARD,
  BANK_TRANSFER,
  PAYPAL,
  OTHER,
}

// Invoice Status Enum
enum InvoiceStatus {
  DRAFT,
  SENT,
  PAID,
  OVERDUE,
  CANCELLED,
}

// Payout Status Enum
enum PayoutStatus {
  PENDING,
  PROCESSING,
  COMPLETED,
  FAILED,
}

// Payment Model
@freezed
class Payment with _\$Payment {
  const factory Payment({
    required String id,
    required String appointmentId,
    required String clientId,
    required String practitionerId,
    required int amount,
    @Default('GBP') String currency,
    required PaymentStatus status,
    @Default(PaymentMethod.CARD) PaymentMethod method,
    String? stripePaymentId,
    String? stripeChargeId,
    String? description,
    String? receiptUrl,
    int? refundedAmount,
    DateTime? refundedAt,
    String? refundReason,
    int? platformFee,
    int? stripeFee,
    int? netAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    PaymentUser? client,
    PaymentPractitioner? practitioner,
    Invoice? invoice,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _\$PaymentFromJson(json);
}

@freezed
class PaymentUser with _\$PaymentUser {
  const factory PaymentUser({
    required String id,
    required String name,
    required String email,
  }) = _PaymentUser;

  factory PaymentUser.fromJson(Map<String, dynamic> json) =>
      _\$PaymentUserFromJson(json);
}

@freezed
class PaymentPractitioner with _\$PaymentPractitioner {
  const factory PaymentPractitioner({
    required String id,
    required String name,
    required String email,
    PaymentPractitionerProfile? practitionerProfile,
  }) = _PaymentPractitioner;

  factory PaymentPractitioner.fromJson(Map<String, dynamic> json) =>
      _\$PaymentPractitionerFromJson(json);
}

@freezed
class PaymentPractitionerProfile with _\$PaymentPractitionerProfile {
  const factory PaymentPractitionerProfile({
    String? practiceName,
  }) = _PaymentPractitionerProfile;

  factory PaymentPractitionerProfile.fromJson(Map<String, dynamic> json) =>
      _\$PaymentPractitionerProfileFromJson(json);
}

// Invoice Model
@freezed
class Invoice with _\$Invoice {
  const factory Invoice({
    required String id,
    required String paymentId,
    required String clientId,
    required String practitionerId,
    required String invoiceNumber,
    required InvoiceStatus status,
    required int subtotal,
    @Default(0) int taxAmount,
    required int total,
    required DateTime issueDate,
    required DateTime dueDate,
    DateTime? paidDate,
    String? pdfUrl,
    DateTime? pdfGeneratedAt,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
    Payment? payment,
    PaymentUser? client,
    PaymentPractitioner? practitioner,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _\$InvoiceFromJson(json);
}

// Payment Summary Model
@freezed
class PaymentSummary with _\$PaymentSummary {
  const factory PaymentSummary({
    required int totalPayments,
    required int totalAmount,
    required int totalRefunded,
    required int completedCount,
    required int pendingCount,
    required int failedCount,
  }) = _PaymentSummary;

  factory PaymentSummary.fromJson(Map<String, dynamic> json) =>
      _\$PaymentSummaryFromJson(json);
}

// Payment Statistics Model
@freezed
class PaymentStatistics with _\$PaymentStatistics {
  const factory PaymentStatistics({
    required String date,
    required int amount,
    required int count,
  }) = _PaymentStatistics;

  factory PaymentStatistics.fromJson(Map<String, dynamic> json) =>
      _\$PaymentStatisticsFromJson(json);
}

// Payout Model
@freezed
class Payout with _\$Payout {
  const factory Payout({
    required String id,
    required String practitionerId,
    required int amount,
    @Default('GBP') String currency,
    required PayoutStatus status,
    String? stripePayoutId,
    String? stripeTransferId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? description,
    @Default(0) int paymentCount,
    DateTime? scheduledFor,
    DateTime? completedAt,
    String? failureReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    PayoutPractitioner? practitioner,
    List<Payment>? payments,
  }) = _Payout;

  factory Payout.fromJson(Map<String, dynamic> json) =>
      _\$PayoutFromJson(json);
}

@freezed
class PayoutPractitioner with _\$PayoutPractitioner {
  const factory PayoutPractitioner({
    required String id,
    required String userId,
    String? practiceName,
    PayoutUser? user,
  }) = _PayoutPractitioner;

  factory PayoutPractitioner.fromJson(Map<String, dynamic> json) =>
      _\$PayoutPractitionerFromJson(json);
}

@freezed
class PayoutUser with _\$PayoutUser {
  const factory PayoutUser({
    required String id,
    required String name,
    required String email,
  }) = _PayoutUser;

  factory PayoutUser.fromJson(Map<String, dynamic> json) =>
      _\$PayoutUserFromJson(json);
}

// Payout Summary Model
@freezed
class PayoutSummary with _\$PayoutSummary {
  const factory PayoutSummary({
    required int totalPayouts,
    required int totalAmount,
    required int pendingAmount,
    required int completedAmount,
    DateTime? nextPayoutDate,
    required int unpaidPaymentsCount,
    required int unpaidPaymentsAmount,
  }) = _PayoutSummary;

  factory PayoutSummary.fromJson(Map<String, dynamic> json) =>
      _\$PayoutSummaryFromJson(json);
}

// Payout Statistics Model
@freezed
class PayoutStatistics with _\$PayoutStatistics {
  const factory PayoutStatistics({
    required String date,
    required int amount,
    required int count,
    required int paymentCount,
  }) = _PayoutStatistics;

  factory PayoutStatistics.fromJson(Map<String, dynamic> json) =>
      _\$PayoutStatisticsFromJson(json);
}

// Response Models
@freezed
class GetPaymentsResponse with _\$GetPaymentsResponse {
  const factory GetPaymentsResponse({
    required List<Payment> payments,
    required int total,
  }) = _GetPaymentsResponse;

  factory GetPaymentsResponse.fromJson(Map<String, dynamic> json) =>
      _\$GetPaymentsResponseFromJson(json);
}

@freezed
class GetInvoicesResponse with _\$GetInvoicesResponse {
  const factory GetInvoicesResponse({
    required List<Invoice> invoices,
    required int total,
  }) = _GetInvoicesResponse;

  factory GetInvoicesResponse.fromJson(Map<String, dynamic> json) =>
      _\$GetInvoicesResponseFromJson(json);
}

@freezed
class GetPayoutsResponse with _\$GetPayoutsResponse {
  const factory GetPayoutsResponse({
    required List<Payout> payouts,
    required int total,
  }) = _GetPayoutsResponse;

  factory GetPayoutsResponse.fromJson(Map<String, dynamic> json) =>
      _\$GetPayoutsResponseFromJson(json);
}
