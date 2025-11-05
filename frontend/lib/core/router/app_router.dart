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
import 'package:sana_app/presentation/screens/appointments/book_appointment_screen.dart';
import 'package:sana_app/presentation/screens/appointments/appointments_list_screen.dart';
import 'package:sana_app/presentation/screens/appointments/payment_screen.dart';
import 'package:sana_app/presentation/screens/practitioner/session_notes_screen.dart';
import 'package:sana_app/presentation/screens/practitioner/outcomes_screen.dart';
import 'package:sana_app/presentation/screens/notifications_list_screen.dart';
import 'package:sana_app/presentation/screens/notification_preferences_screen.dart';
import 'package:sana_app/presentation/screens/analytics/client_analytics_screen.dart';
import 'package:sana_app/presentation/screens/analytics/practitioner_analytics_screen.dart';
import 'package:sana_app/presentation/screens/reviews/submit_review_screen.dart';
import 'package:sana_app/presentation/screens/reviews/reviews_list_screen.dart';
import 'package:sana_app/presentation/screens/search/practitioner_search_screen.dart';
import 'package:sana_app/presentation/screens/messages/conversations_list_screen.dart';
import 'package:sana_app/presentation/screens/messages/chat_screen.dart';
import 'package:sana_app/presentation/screens/availability/availability_management_screen.dart';
import 'package:sana_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:sana_app/presentation/screens/admin/user_management_screen.dart';
import 'package:sana_app/presentation/screens/admin/practitioner_verification_screen.dart';
import 'package:sana_app/data/models/practitioner.dart';
import 'package:sana_app/data/models/message.dart';

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
        builder: (context, state) => const PractitionerSearchScreen(),
      ),
      // Phase 3: Appointments & Payments Routes
      GoRoute(
        path: AppConstants.routeAppointments,
        builder: (context, state) => const AppointmentsListScreen(),
      ),
      GoRoute(
        path: AppConstants.routeBookAppointment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null ||
              !extra.containsKey('practitionerId') ||
              !extra.containsKey('sessionType')) {
            return const Scaffold(
              body: Center(child: Text('Missing booking information')),
            );
          }
          return BookAppointmentScreen(
            practitionerId: extra['practitionerId'] as String,
            sessionType: extra['sessionType'] as SessionType,
          );
        },
      ),
      GoRoute(
        path: '/appointments/:id/payment',
        builder: (context, state) {
          final appointmentId = state.pathParameters['id'];
          if (appointmentId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid appointment ID')),
            );
          }
          return PaymentScreen(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: AppConstants.routeSessionNotes,
        builder: (context, state) => const SessionNotesScreen(),
      ),
      GoRoute(
        path: AppConstants.routeOutcomes,
        builder: (context, state) => const OutcomesScreen(),
      ),
      // Phase 4: Notifications Routes
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsListScreen(),
      ),
      GoRoute(
        path: '/notification-preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      // Phase 4: Analytics Routes
      GoRoute(
        path: '/analytics/client',
        builder: (context, state) => const ClientAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/practitioner',
        builder: (context, state) => const PractitionerAnalyticsScreen(),
      ),
      // Phase 4: Reviews Routes
      GoRoute(
        path: '/reviews/submit/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return SubmitReviewScreen(
            appointmentId: appointmentId,
            practitionerName: extra?['practitionerName'] ?? '',
            sessionTypeName: extra?['sessionTypeName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/reviews/practitioner/:practitionerId',
        builder: (context, state) {
          final practitionerId = state.pathParameters['practitionerId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ReviewsListScreen(
            practitionerId: practitionerId,
            practitionerName: extra?['practitionerName'] ?? 'Practitioner',
          );
        },
      ),
      // Phase 4: Messaging Routes
      GoRoute(
        path: AppConstants.routeMessages,
        builder: (context, state) => const ConversationsListScreen(),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            conversationId: conversationId,
            conversation: extra?['conversation'] as Conversation?,
            otherUser: extra?['otherUser'] as ConversationUser?,
          );
        },
      ),
      // Phase 4: Availability Routes
      GoRoute(
        path: AppConstants.routeAvailabilityManagement,
        builder: (context, state) => const AvailabilityManagementScreen(),
      ),
      // Phase 4: Admin Routes
      GoRoute(
        path: AppConstants.routeAdminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminUsers,
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminVerifications,
        builder: (context, state) => const PractitionerVerificationScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminReviews,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Review Moderation'),
      ),
      GoRoute(
        path: AppConstants.routeAdminAppointments,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Appointment Management'),
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
