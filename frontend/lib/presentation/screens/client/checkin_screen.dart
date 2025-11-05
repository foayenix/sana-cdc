import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/data/models/daily_checkin.dart';
import 'package:sana_app/data/services/checkin_service.dart';
import 'package:sana_app/presentation/widgets/emoji_slider.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int _sleepQuality = 3;
  int _energyLevel = 3;
  int _mood = 3;
  int _stressLevel = 3;
  bool _isSubmitting = false;

  Future<void> _submitCheckin() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = CheckinRequest(
        sleepQuality: _sleepQuality,
        energyLevel: _energyLevel,
        mood: _mood,
        stressLevel: _stressLevel,
      );

      final service = ref.read(checkinServiceProvider);
      final response = await service.submitCheckin(request);

      if (mounted) {
        // Show success dialog with score update
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Check-in Recorded!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your health score has been updated to ${response.data.updatedScore}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${_formatStatus(response.data.updatedStatus)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // Close dialog
                  context.pop(); // Go back to dashboard
                },
                child: const Text('Done'),
              ),
            ],
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
        setState(() {
          _isSubmitting = false,
        });
      }
    }
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'NEEDS_SUPPORT':
        return 'Needs Support';
      case 'REBUILDING':
        return 'Rebuilding';
      case 'BALANCED':
        return 'Balanced';
      case 'THRIVING':
        return 'Thriving';
      case 'RADIANT':
        return 'Radiant';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a moment to reflect on your wellness',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            EmojiSlider(
              label: '😴 Sleep Quality',
              emojis: const ['💤', '😪', '😌', '🛌', '✨'],
              value: _sleepQuality,
              onChanged: (value) {
                setState(() {
                  _sleepQuality = value;
                });
              },
            ),
            const SizedBox(height: 24),
            EmojiSlider(
              label: '⚡ Energy Level',
              emojis: const ['🔋', '🪫', '⚡', '🔥', '💪'],
              value: _energyLevel,
              onChanged: (value) {
                setState(() {
                  _energyLevel = value;
                });
              },
            ),
            const SizedBox(height: 24),
            EmojiSlider(
              label: '😊 Mood',
              emojis: const ['😢', '😕', '😐', '🙂', '😄'],
              value: _mood,
              onChanged: (value) {
                setState(() {
                  _mood = value;
                });
              },
            ),
            const SizedBox(height: 24),
            EmojiSlider(
              label: '😰 Stress Level',
              emojis: const ['😌', '🙂', '😐', '😟', '😰'],
              value: _stressLevel,
              onChanged: (value) {
                setState(() {
                  _stressLevel = value;
                });
              },
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Submit Check-In',
              onPressed: _submitCheckin,
              isLoading: _isSubmitting,
              width: double.infinity,
            ),
            const SizedBox(height: 16),
            Text(
              'This will update your SANA Health Score',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
