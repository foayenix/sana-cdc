import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sana_app/core/constants/app_constants.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/data/models/questionnaire_response.dart';
import 'package:sana_app/data/services/questionnaire_service.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Physical domain
  double _sleepHours = 7.0;
  int _sleepQuality = 3;
  int _painLevel = 0;
  int _energyLevel = 3;

  // Mental domain
  int _moodScore = 3;
  int _anxietyLevel = 3;
  int _stressLevel = 3;

  // Lifestyle domain
  int _exerciseMinutesPerWeek = 0;
  int _dietQuality = 3;
  int _alcoholDrinksPerWeek = 0;

  // Social domain
  int _socialConnection = 3;
  int _lifeSatisfaction = 3;
  int _workLifeBalance = 3;

  // Additional context
  List<String> _mainHealthConcerns = [];
  List<String> _practitionerTypes = [];

  final List<String> _healthConcernOptions = [
    'Sleep',
    'Stress',
    'Pain',
    'Digestion',
    'Energy',
    'Mood',
    'Hormones',
    'Immunity',
    'Skin',
    'Weight',
    'Other',
  ];

  final List<String> _practitionerTypeOptions = [
    'Herbalist',
    'Nutritionist',
    'Acupuncturist',
    'Massage Therapist',
    'Homeopath',
    'Naturopath',
    'Other',
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitQuestionnaire() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = QuestionnaireResponse(
        sleepHours: _sleepHours,
        sleepQuality: _sleepQuality,
        painLevel: _painLevel,
        energyLevel: _energyLevel,
        moodScore: _moodScore,
        anxietyLevel: _anxietyLevel,
        stressLevel: _stressLevel,
        exerciseMinutesPerWeek: _exerciseMinutesPerWeek,
        dietQuality: _dietQuality,
        alcoholDrinksPerWeek: _alcoholDrinksPerWeek,
        socialConnection: _socialConnection,
        lifeSatisfaction: _lifeSatisfaction,
        workLifeBalance: _workLifeBalance,
        mainHealthConcerns: _mainHealthConcerns,
        practitionerTypesLooking: _practitionerTypes,
      );

      final service = ref.read(questionnaireServiceProvider);
      await service.submitQuestionnaire(response);

      if (mounted) {
        context.go(AppConstants.routeDashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting questionnaire: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Questionnaire'),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildStepContent(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPhysicalDomain();
      case 1:
        return _buildMentalDomain();
      case 2:
        return _buildLifestyleDomain();
      case 3:
        return _buildSocialDomain();
      case 4:
        return _buildAdditionalContext();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPhysicalDomain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Physical Health',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s start with your physical wellness',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        Text('How many hours of sleep do you get per night?'),
        Slider(
          value: _sleepHours,
          min: 0,
          max: 12,
          divisions: 24,
          label: '${_sleepHours.toStringAsFixed(1)} hours',
          onChanged: (value) {
            setState(() {
              _sleepHours = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildRatingQuestion(
          'How would you rate your sleep quality?',
          _sleepQuality,
          ['Very Poor', 'Poor', 'Fair', 'Good', 'Excellent'],
          (value) {
            setState(() {
              _sleepQuality = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildScaleQuestion(
          'On a scale of 0-10, how would you rate your pain/discomfort level?',
          _painLevel,
          10,
          (value) {
            setState(() {
              _painLevel = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildRatingQuestion(
          'How would you describe your energy levels?',
          _energyLevel,
          ['Exhausted', 'Low', 'Moderate', 'High', 'Energetic'],
          (value) {
            setState(() {
              _energyLevel = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMentalDomain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mental Wellness',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Now let\'s explore your mental health',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        _buildRatingQuestion(
          'How often do you feel happy or content?',
          _moodScore,
          ['Rarely', 'Sometimes', 'Often', 'Very Often', 'Always'],
          (value) {
            setState(() {
              _moodScore = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildRatingQuestion(
          'How anxious do you feel in daily life?',
          _anxietyLevel,
          ['Not at all', 'Slightly', 'Moderately', 'Very', 'Extremely'],
          (value) {
            setState(() {
              _anxietyLevel = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildRatingQuestion(
          'How stressed do you feel?',
          _stressLevel,
          ['Not at all', 'Slightly', 'Moderately', 'Very', 'Extremely'],
          (value) {
            setState(() {
              _stressLevel = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLifestyleDomain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lifestyle',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your daily habits',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        Text('How many minutes of exercise/movement do you do per week?'),
        Slider(
          value: _exerciseMinutesPerWeek.toDouble(),
          min: 0,
          max: 500,
          divisions: 10,
          label: '$_exerciseMinutesPerWeek min',
          onChanged: (value) {
            setState(() {
              _exerciseMinutesPerWeek = value.toInt();
            });
          },
        ),
        const SizedBox(height: 24),
        _buildRatingQuestion(
          'How would you rate your diet quality?',
          _dietQuality,
          ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent'],
          (value) {
            setState(() {
              _dietQuality = value;
            });
          },
        ),
        const SizedBox(height: 24),
        Text('How many alcoholic drinks do you have per week?'),
        Slider(
          value: _alcoholDrinksPerWeek.toDouble(),
          min: 0,
          max: 20,
          divisions: 20,
          label: '$_alcoholDrinksPerWeek drinks',
          onChanged: (value) {
            setState(() {
              _alcoholDrinksPerWeek = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSocialDomain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Wellness',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Finally, let\'s look at your social connections',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        _buildRatingQuestion(
          'How connected do you feel to friends/family?',
          _socialConnection,
          ['Very isolated', 'Isolated', 'Neutral', 'Connected', 'Very connected'],
          (value) {
            setState(() {
              _socialConnection = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildRatingQuestion(
          'How satisfied are you with your life overall?',
          _lifeSatisfaction,
          ['Very dissatisfied', 'Dissatisfied', 'Neutral', 'Satisfied', 'Very satisfied'],
          (value) {
            setState(() {
              _lifeSatisfaction = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildRatingQuestion(
          'How would you rate your work-life balance?',
          _workLifeBalance,
          ['Very poor', 'Poor', 'Fair', 'Good', 'Excellent'],
          (value) {
            setState(() {
              _workLifeBalance = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalContext() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Help us understand your needs better',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        Text(
          'What are your main health concerns?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _healthConcernOptions.map((concern) {
            final isSelected = _mainHealthConcerns.contains(concern);
            return FilterChip(
              label: Text(concern),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _mainHealthConcerns.add(concern);
                  } else {
                    _mainHealthConcerns.remove(concern);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'What type of practitioner are you looking for?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _practitionerTypeOptions.map((type) {
            final isSelected = _practitionerTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _practitionerTypes.add(type);
                  } else {
                    _practitionerTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingQuestion(
    String question,
    int currentValue,
    List<String> labels,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final value = index + 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentValue == value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        value.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentValue == value
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: currentValue == value
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildScaleQuestion(
    String question,
    int currentValue,
    int maxValue,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question),
        const SizedBox(height: 12),
        Slider(
          value: currentValue.toDouble(),
          min: 0,
          max: maxValue.toDouble(),
          divisions: maxValue,
          label: currentValue.toString(),
          onChanged: (value) => onChanged(value.toInt()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: Theme.of(context).textTheme.bodySmall),
            Text('$maxValue', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Back',
                onPressed: _previousStep,
                isOutlined: true,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: _currentStep == 4 ? 'Submit' : 'Continue',
              onPressed: _currentStep == 4 ? _submitQuestionnaire : _nextStep,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}
