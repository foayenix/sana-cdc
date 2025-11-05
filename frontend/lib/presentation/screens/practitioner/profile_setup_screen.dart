import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/custom_text_field.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/data/services/practitioners_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form fields
  final _practiceNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _yearsController = TextEditingController();
  final _professionalBodyController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _approachController = TextEditingController();

  List<String> _selectedSpecialties = [];
  List<String> _qualifications = [];
  final _qualificationController = TextEditingController();

  final List<String> _availableSpecialties = [
    'Nutritionist',
    'Personal Trainer',
    'Physiotherapist',
    'Psychologist',
    'Yoga Instructor',
    'Meditation Teacher',
    'Life Coach',
    'Acupuncturist',
    'Massage Therapist',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _practiceNameController.dispose();
    _bioController.dispose();
    _postcodeController.dispose();
    _yearsController.dispose();
    _professionalBodyController.dispose();
    _insuranceNumberController.dispose();
    _aboutMeController.dispose();
    _approachController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitProfile();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final practitionersService = ref.read(practitionersServiceProvider);

      final profileData = {
        'practiceName': _practiceNameController.text,
        'bio': _bioController.text,
        'postcode': _postcodeController.text,
        'specialties': _selectedSpecialties,
        'yearsOfPractice': int.tryParse(_yearsController.text) ?? 0,
        'professionalBody': _professionalBodyController.text,
        'qualifications': _qualifications,
        'insuranceNumber': _insuranceNumberController.text,
        'aboutMe': _aboutMeController.text,
        'approach': _approachController.text,
      };

      await practitionersService.updateProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(),

                // Form Pages
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(),
                        _buildProfessionalInfoStep(),
                        _buildQualificationsStep(),
                        _buildAboutMeStep(),
                      ],
                    ),
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Step 1 of 4',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _practiceNameController,
            label: 'Practice Name',
            hint: 'e.g., Wellness Center',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your practice name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _bioController,
            label: 'Short Bio',
            hint: 'Brief description of your practice',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a short bio';
              }
              if (value.length < 20) {
                return 'Bio should be at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _postcodeController,
            label: 'Postcode',
            hint: 'e.g., SW1A 1AA',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your postcode';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          Text(
            'Specialties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSpecialties.map((specialty) {
              final isSelected = _selectedSpecialties.contains(specialty);
              return FilterChip(
                label: Text(specialty),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecialties.add(specialty);
                    } else {
                      _selectedSpecialties.remove(specialty);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2 of 4',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _yearsController,
            label: 'Years of Practice',
            hint: 'e.g., 10',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter years of practice';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _professionalBodyController,
            label: 'Professional Body (Optional)',
            hint: 'e.g., British Association of Nutritionists',
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _insuranceNumberController,
            label: 'Professional Insurance Number (Optional)',
            hint: 'Your insurance policy number',
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qualifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3 of 4',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          Text(
            'Add your qualifications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qualificationController,
                  decoration: const InputDecoration(
                    labelText: 'Qualification',
                    hintText: 'e.g., BSc Nutrition',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  if (_qualificationController.text.isNotEmpty) {
                    setState(() {
                      _qualifications.add(_qualificationController.text);
                      _qualificationController.clear();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_qualifications.isNotEmpty) ...[
            Text(
              'Your Qualifications:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._qualifications.map((qual) => Card(
                  child: ListTile(
                    title: Text(qual),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _qualifications.remove(qual);
                        });
                      },
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutMeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About You',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Step 4 of 4',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _aboutMeController,
            label: 'About Me',
            hint: 'Tell clients about yourself and your background',
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please tell clients about yourself';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _approachController,
            label: 'Your Approach',
            hint: 'Describe your approach to wellness and client care',
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your approach';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: _currentStep == 3 ? 'Complete' : 'Next',
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
  }
}
