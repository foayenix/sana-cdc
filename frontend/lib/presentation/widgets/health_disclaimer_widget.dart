import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class HealthDisclaimerWidget extends StatelessWidget {
  final bool compact;
  final bool showBorder;

  const HealthDisclaimerWidget({
    super.key,
    this.compact = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactDisclaimer(context);
    }
    return _buildFullDisclaimer(context);
  }

  Widget _buildCompactDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.orange.shade50,
            )
          : null,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This platform does not provide medical advice. Always consult your physician.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.orange.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.orange.shade50,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Important Health Disclaimer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This platform does NOT provide medical advice, diagnosis, or treatment.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade900,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The information provided is for general informational purposes only and is not a substitute for professional medical advice. Always seek the advice of your physician or qualified health provider with any questions regarding a medical condition.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange.shade800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.emergency, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'In case of emergency, call 999 immediately.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                context.push(AppConstants.routeTermsOfService);
              },
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('Read Full Terms of Service'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthDisclaimerDialog extends StatelessWidget {
  const HealthDisclaimerDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const HealthDisclaimerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Health Disclaimer'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before proceeding, please acknowledge the following:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              '• This platform does NOT provide medical advice\n'
              '• Information is for general purposes only\n'
              '• Always consult your physician for medical concerns\n'
              '• In emergencies, call 999 immediately\n'
              '• Practitioners are independent and not employed by us\n'
              '• We do not guarantee any health outcomes',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'For medical emergencies, always call 999',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I Understand'),
        ),
      ],
    );
  }
}
