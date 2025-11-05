import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sana_app/core/constants/app_constants.dart';
import 'package:sana_app/core/theme/app_colors.dart';
import 'package:sana_app/presentation/providers/auth_provider.dart';
import 'package:sana_app/presentation/screens/auth/login_screen.dart';
import 'package:sana_app/presentation/screens/auth/signup_screen.dart';
import 'package:sana_app/presentation/screens/onboarding/questionnaire_screen.dart';
import 'package:sana_app/presentation/screens/client/dashboard_screen.dart';
import 'package:sana_app/presentation/screens/client/checkin_screen.dart';
import 'package:sana_app/presentation/screens/client/recommendations_screen.dart';

// Splash Screen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      final user = authState.user;
      if (user?.clientProfile?.questionnaireCompleted == false) {
        context.go(AppConstants.routeQuestionnaire);
      } else {
        context.go(AppConstants.routeDashboard);
      }
    } else {
      context.go(AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SANA',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your path to wellness',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for remaining screens
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title - Coming Soon'),
      ),
    );
  }
}

// Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSignup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppConstants.routeQuestionnaire,
        builder: (context, state) => const QuestionnaireScreen(),
      ),
      GoRoute(
        path: AppConstants.routeDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCheckin,
        builder: (context, state) => const CheckinScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRecommendations,
        builder: (context, state) => const RecommendationsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (context, state) => const PlaceholderScreen(title: 'Profile'),
      ),
      GoRoute(
        path: AppConstants.routePractitioners,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Find Practitioners'),
      ),
      GoRoute(
        path: AppConstants.routeAppointments,
        builder: (context, state) => const PlaceholderScreen(title: 'Appointments'),
      ),
      GoRoute(
        path: AppConstants.routeJournal,
        builder: (context, state) => const PlaceholderScreen(title: 'Journal'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
