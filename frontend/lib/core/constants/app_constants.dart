class AppConstants {
  // App Info
  static const String appName = 'SANA Wellness';
  static const String tagline = 'Your path to wellness';

  // Pagination
  static const int defaultPageSize = 20;

  // Health Score
  static const int maxHealthScore = 100;
  static const int minHealthScore = 0;

  // Health Score Status Levels
  static const String statusRadiant = 'RADIANT';
  static const String statusThriving = 'THRIVING';
  static const String statusBalanced = 'BALANCED';
  static const String statusRebuilding = 'REBUILDING';
  static const String statusNeedsSupport = 'NEEDS_SUPPORT';

  // Check-in Scale
  static const int minCheckInValue = 1;
  static const int maxCheckInValue = 5;

  // Time Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Validation
  static const int minPasswordLength = 8;
  static const int minNameLength = 2;
  static const int maxBioLength = 500;
  static const int maxNotesLength = 2000;

  // File Upload
  static const int maxProfilePhotoSize = 5 * 1024 * 1024; // 5MB
  static const int maxCredentialFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxCredentialFiles = 5;

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'Something went wrong. Please try again.';
  static const String sessionExpired = 'Your session has expired. Please log in again.';

  // Success Messages
  static const String loginSuccess = 'Welcome back!';
  static const String signupSuccess = 'Account created successfully!';
  static const String updateSuccess = 'Updated successfully!';
  static const String deleteSuccess = 'Deleted successfully!';

  // Routes (will be defined in router)
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeQuestionnaire = '/questionnaire';
  static const String routeDashboard = '/dashboard';
  static const String routeCheckin = '/checkin';
  static const String routeRecommendations = '/recommendations';
  static const String routeProfile = '/profile';
  static const String routePractitioners = '/practitioners';
  static const String routeAppointments = '/appointments';
  static const String routeJournal = '/journal';

  // Phase 3: Appointments & Payments Routes
  static const String routeBookAppointment = '/book-appointment';
  static const String routeAppointmentPayment = '/appointments/:id/payment';
  static const String routeSessionNotes = '/session-notes';
  static const String routeOutcomes = '/outcomes';

  // Phase 4: Notifications Routes
  static const String routeNotifications = '/notifications';
  static const String routeNotificationPreferences = '/notification-preferences';

  // Phase 4: Analytics Routes
  static const String routeClientAnalytics = '/analytics/client';
  static const String routePractitionerAnalytics = '/analytics/practitioner';

  // Phase 4: Reviews Routes
  static const String routeSubmitReview = '/reviews/submit';
  static const String routePractitionerReviews = '/reviews/practitioner';

  // Phase 4: Search Routes
  static const String routePractitionerSearch = '/practitioners';
  static const String routePractitionerProfile = '/practitioner-profile';

  // Phase 4: Messaging Routes
  static const String routeMessages = '/messages';
  static const String routeChat = '/messages/:id';

  // Phase 4: Availability Routes
  static const String routeAvailabilityManagement = '/availability-management';

  // Phase 4: Admin Routes
  static const String routeAdminDashboard = '/admin/dashboard';
  static const String routeAdminUsers = '/admin/users';
  static const String routeAdminVerifications = '/admin/verifications';
  static const String routeAdminReviews = '/admin/reviews';
  static const String routeAdminAppointments = '/admin/appointments';

  // User Roles
  static const String roleClient = 'CLIENT';
  static const String rolePractitioner = 'PRACTITIONER';
  static const String roleAdmin = 'ADMIN';
}
