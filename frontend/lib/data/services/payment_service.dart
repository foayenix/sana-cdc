import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../../core/constants/api_constants.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

class PaymentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer \$token';
  }

  // Payment History
  Future<GetPaymentsResponse> getPayments({
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? minAmount,
    int? maxAmount,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (status != null) queryParams['status'] = status.name;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (minAmount != null) queryParams['minAmount'] = minAmount.toString();
      if (maxAmount != null) queryParams['maxAmount'] = maxAmount.toString();

      final response = await _dio.get(
        '/payment-history/payments',
        queryParameters: queryParams,
      );

      return GetPaymentsResponse.fromJson({
        'payments': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Payment> getPaymentById(String id) async {
    try {
      final response = await _dio.get('/payment-history/payments/\$id');
      return Payment.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PaymentSummary> getPaymentSummary() async {
    try {
      final response = await _dio.get('/payment-history/summary');
      return PaymentSummary.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PaymentStatistics>> getPaymentStatistics({
    String period = 'month',
  }) async {
    try {
      final response = await _dio.get(
        '/payment-history/statistics',
        queryParameters: {'period': period},
      );
      return (response.data['data'] as List)
          .map((json) => PaymentStatistics.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Invoices
  Future<GetInvoicesResponse> getInvoices({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/payment-history/invoices',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      return GetInvoicesResponse.fromJson({
        'invoices': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Invoice> getInvoiceById(String id) async {
    try {
      final response = await _dio.get('/payment-history/invoices/\$id');
      return Invoice.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Payouts (for practitioners)
  Future<GetPayoutsResponse> getPayouts({
    PayoutStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (status != null) queryParams['status'] = status.name;

      final response = await _dio.get(
        '/payouts',
        queryParameters: queryParams,
      );

      return GetPayoutsResponse.fromJson({
        'payouts': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Payout> getPayoutById(String id) async {
    try {
      final response = await _dio.get('/payouts/\$id');
      return Payout.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PayoutSummary> getPayoutSummary() async {
    try {
      final response = await _dio.get('/payouts/summary');
      return PayoutSummary.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<GetPaymentsResponse> getUnpaidPayments({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/payouts/unpaid-payments',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      return GetPaymentsResponse.fromJson({
        'payments': response.data['data'],
        'total': response.data['pagination']['total'],
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PayoutStatistics>> getPayoutStatistics({
    String period = 'month',
  }) async {
    try {
      final response = await _dio.get(
        '/payouts/statistics',
        queryParameters: {'period': period},
      );
      return (response.data['data'] as List)
          .map((json) => PayoutStatistics.fromJson(json))
          .toList();
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

  // Helper methods for formatting
  static String formatAmount(int amountInPence, {String currency = 'GBP'}) {
    final amount = amountInPence / 100;
    final symbol = currency == 'GBP' ? '£' : '\$';
    return '\$symbol\${amount.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    return '\${date.day}/\${date.month}/\${date.year}';
  }

  static String formatDateTime(DateTime date) {
    return '\${date.day}/\${date.month}/\${date.year} \${date.hour}:\${date.minute.toString().padLeft(2, '0')}';
  }
}

// State Management with Riverpod

// Payments State
class PaymentsState {
  final List<Payment> payments;
  final int total;
  final bool isLoading;
  final String? error;
  final PaymentSummary? summary;

  PaymentsState({
    this.payments = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.summary,
  });

  PaymentsState copyWith({
    List<Payment>? payments,
    int? total,
    bool? isLoading,
    String? error,
    PaymentSummary? summary,
  }) {
    return PaymentsState(
      payments: payments ?? this.payments,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final PaymentService _paymentService;

  PaymentsNotifier(this._paymentService) : super(PaymentsState());

  Future<void> loadPayments({
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? minAmount,
    int? maxAmount,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _paymentService.getPayments(
        status: status,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        payments: offset == 0 ? response.payments : [...state.payments, ...response.payments],
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSummary() async {
    try {
      final summary = await _paymentService.getPaymentSummary();
      state = state.copyWith(summary: summary);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => loadPayments();
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return PaymentsNotifier(paymentService);
});

// Payouts State
class PayoutsState {
  final List<Payout> payouts;
  final int total;
  final bool isLoading;
  final String? error;
  final PayoutSummary? summary;

  PayoutsState({
    this.payouts = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.summary,
  });

  PayoutsState copyWith({
    List<Payout>? payouts,
    int? total,
    bool? isLoading,
    String? error,
    PayoutSummary? summary,
  }) {
    return PayoutsState(
      payouts: payouts ?? this.payouts,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
    );
  }
}

class PayoutsNotifier extends StateNotifier<PayoutsState> {
  final PaymentService _paymentService;

  PayoutsNotifier(this._paymentService) : super(PayoutsState());

  Future<void> loadPayouts({
    PayoutStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _paymentService.getPayouts(
        status: status,
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        payouts: offset == 0 ? response.payouts : [...state.payouts, ...response.payouts],
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSummary() async {
    try {
      final summary = await _paymentService.getPayoutSummary();
      state = state.copyWith(summary: summary);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void refresh() => loadPayouts();
}

final payoutsProvider = StateNotifierProvider<PayoutsNotifier, PayoutsState>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return PayoutsNotifier(paymentService);
});
