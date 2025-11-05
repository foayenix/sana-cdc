import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/core/widgets/error_widget.dart';
import 'package:sana_app/data/models/appointment.dart';
import 'package:sana_app/data/services/appointments_service.dart';
import 'package:sana_app/data/services/payments_service.dart';

// Provider for fetching appointment details
final appointmentProvider =
    FutureProvider.autoDispose.family<Appointment, String>(
  (ref, appointmentId) async {
    final service = ref.watch(appointmentsServiceProvider);
    return await service.getAppointmentById(appointmentId);
  },
);

class PaymentScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const PaymentScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool isProcessing = false;

  Future<void> _processPayment(Appointment appointment) async {
    setState(() => isProcessing = true);

    try {
      // Step 1: Create payment intent
      final paymentsService = ref.read(paymentsServiceProvider);
      final paymentIntent = await paymentsService.createPaymentIntent(
        appointmentId: widget.appointmentId,
      );

      // Step 2: Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          merchantDisplayName: 'SANA Wellness',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF6200EE),
                  text: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );

      // Step 3: Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Your appointment is confirmed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to appointments list
        context.go('/appointments');
      }
    } on StripeException catch (e) {
      if (mounted) {
        String message = 'Payment failed';
        if (e.error.code == FailureCode.Canceled) {
          message = 'Payment cancelled';
        } else {
          message = e.error.localizedMessage ?? 'Payment failed';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentAsync = ref.watch(appointmentProvider(widget.appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: appointmentAsync.when(
        data: (appointment) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPaymentHeader(),
              _buildAppointmentSummary(appointment),
              const Divider(height: 32),
              _buildPriceBreakdown(appointment),
              const Divider(height: 32),
              _buildPaymentInfo(),
              const SizedBox(height: 100),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => CustomErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(appointmentProvider(widget.appointmentId)),
        ),
      ),
      bottomNavigationBar: appointmentAsync.maybeWhen(
        data: (appointment) => _buildPayButton(appointment),
        orElse: () => null,
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.payment,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Stripe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock,
            color: Colors.green[700],
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary(Appointment appointment) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.person,
            'Practitioner',
            appointment.practitioner?.user.name ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.medical_services,
            'Session Type',
            appointment.sessionType?.name ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            DateFormat('EEEE, MMMM d, y').format(appointment.appointmentDate),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            DateFormat('HH:mm').format(appointment.appointmentDate),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.timer,
            'Duration',
            '${appointment.sessionType?.durationMinutes ?? 0} minutes',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(Appointment appointment) {
    final price = appointment.sessionType?.priceGBP ?? 0.0;
    final subtotal = price;
    final total = subtotal;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Session Fee', style: TextStyle(fontSize: 16)),
              Text(
                '£${price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '£${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            Icons.credit_card,
            'Secure Payment',
            'Your payment information is encrypted and secure.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            Icons.receipt,
            'Instant Receipt',
            'You will receive a receipt via email immediately.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            Icons.event_available,
            'Confirmation',
            'Your appointment will be confirmed upon successful payment.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            Icons.cancel,
            'Cancellation Policy',
            'Cancel up to 24 hours before for a full refund.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(Appointment appointment) {
    final price = appointment.sessionType?.priceGBP ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: isProcessing
              ? 'Processing...'
              : 'Pay £${price.toStringAsFixed(2)}',
          onPressed: isProcessing ? null : () => _processPayment(appointment),
          isLoading: isProcessing,
        ),
      ),
    );
  }
}
