# SANA Mobile App (Flutter)

The Flutter mobile application for the SANA wellness platform.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK 3.0+
- Android Studio / Xcode (for running on emulators)
- VS Code (recommended IDE)

### Installation

```bash
# Install dependencies
flutter pub get

# Run code generation (for Riverpod, Freezed, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Root app widget
│
├── core/
│   ├── config/                  # App configuration
│   │   └── app_config.dart      # API URLs, storage keys
│   ├── constants/               # Constants
│   │   └── app_constants.dart   # Routes, error messages, etc.
│   ├── theme/                   # Theming
│   │   ├── app_theme.dart       # Material Theme configuration
│   │   └── app_colors.dart      # Color palette
│   ├── router/                  # Navigation
│   │   └── app_router.dart      # GoRouter configuration
│   ├── utils/                   # Utilities
│   │   ├── validators.dart      # Form validators
│   │   ├── formatters.dart      # Date/number formatters
│   │   └── extensions.dart      # Dart extensions
│   └── widgets/                 # Reusable widgets
│       ├── custom_button.dart
│       ├── loading_indicator.dart
│       └── error_widget.dart
│
├── data/
│   ├── models/                  # Data models
│   │   ├── user.dart
│   │   ├── health_score.dart
│   │   ├── questionnaire_response.dart
│   │   ├── daily_checkin.dart
│   │   └── recommendation.dart
│   ├── repositories/            # Data repositories
│   │   ├── auth_repository.dart
│   │   ├── questionnaire_repository.dart
│   │   ├── checkin_repository.dart
│   │   └── recommendations_repository.dart
│   └── services/                # API services
│       ├── api_service.dart     # Dio HTTP client
│       ├── auth_service.dart    # Auth API calls
│       └── storage_service.dart # Local storage
│
├── presentation/
│   ├── screens/
│   │   ├── auth/                # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── role_selection_screen.dart
│   │   ├── onboarding/          # Onboarding flow
│   │   │   └── questionnaire_screen.dart
│   │   ├── client/              # Client screens
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── checkin_screen.dart
│   │   │   ├── recommendations_screen.dart
│   │   │   ├── journal_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── practitioner/        # Practitioner screens
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── profile_setup_screen.dart
│   │   │   ├── availability_screen.dart
│   │   │   └── session_notes_screen.dart
│   │   └── shared/              # Shared screens
│   │       ├── search_screen.dart
│   │       ├── booking_screen.dart
│   │       └── appointment_detail_screen.dart
│   ├── widgets/                 # Feature-specific widgets
│   │   ├── health_score_gauge.dart
│   │   ├── emoji_slider.dart
│   │   ├── domain_score_card.dart
│   │   ├── practitioner_card.dart
│   │   └── appointment_card.dart
│   └── providers/               # Riverpod providers
│       ├── auth_provider.dart
│       ├── user_provider.dart
│       ├── health_score_provider.dart
│       └── checkin_provider.dart
│
└── features/                    # Feature-first organization (alternative)
    ├── auth/
    ├── questionnaire/
    ├── dashboard/
    └── checkin/
```

## 🎨 Design System

### Colors

See `lib/core/theme/app_colors.dart` for the complete color palette.

- **Primary**: Purple (#6B4CE6)
- **Secondary**: Green (#34D399)
- **Status colors**: Radiant (Gold), Thriving (Green), Balanced (Blue), etc.

### Typography

Uses Inter font via Google Fonts.

### Component Library

Material 3 design system with custom theming.

## 📊 State Management

Using **Riverpod** for state management.

### Example Provider

```dart
@riverpod
class HealthScore extends _$HealthScore {
  @override
  Future<HealthScoreModel> build() async {
    final repo = ref.read(questionnaireRepositoryProvider);
    return await repo.getHealthScore();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(questionnaireRepositoryProvider);
      return await repo.getHealthScore();
    });
  }
}
```

### Using Providers

```dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthScoreAsync = ref.watch(healthScoreProvider);

    return healthScoreAsync.when(
      data: (score) => HealthScoreGauge(score: score),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error.toString()),
    );
  }
}
```

## 🌐 API Integration

API client is configured in `lib/data/services/api_service.dart` using Dio.

### Making API Calls

```dart
class AuthService {
  final Dio _dio;

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    return AuthResponse.fromJson(response.data);
  }
}
```

### Authentication

JWT tokens are stored in `flutter_secure_storage` and automatically added to requests via an interceptor.

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/health_score_calculator_test.dart

# Run with coverage
flutter test --coverage
```

### Test Structure

```
test/
├── unit/                       # Unit tests
│   ├── health_score_calculator_test.dart
│   └── validators_test.dart
├── widget/                     # Widget tests
│   ├── health_score_gauge_test.dart
│   └── emoji_slider_test.dart
└── integration/                # Integration tests
    └── auth_flow_test.dart
```

## 🚀 Building for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build for iOS
flutter build ios --release

# Create archive (requires Xcode)
# Open ios/Runner.xcworkspace in Xcode and archive
```

## 📦 Dependencies

### Key Packages

- **flutter_riverpod**: State management
- **go_router**: Navigation
- **dio**: HTTP client
- **flutter_form_builder**: Forms
- **fl_chart**: Charts and graphs
- **table_calendar**: Calendar widget
- **google_sign_in**: Google OAuth
- **flutter_secure_storage**: Secure token storage
- **hive**: Local database
- **firebase_messaging**: Push notifications

### Code Generation

Run after modifying models or providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🔐 Environment Configuration

Create a `.env` file (not committed to git):

```bash
API_URL=http://localhost:3000/api
GOOGLE_CLIENT_ID=your-google-client-id
```

Access in code:

```dart
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api');
```

## 🎯 Next Steps (Phase 1 Implementation)

### Week 1-2: Authentication
- [ ] Build login screen UI
- [ ] Build signup screen UI
- [ ] Implement role selection (Client/Practitioner)
- [ ] Integrate with auth API
- [ ] Add Google OAuth button
- [ ] Implement token storage and refresh

### Week 3: Health Questionnaire
- [ ] Build questionnaire multi-step form
- [ ] 15 questions across 4 domains
- [ ] Form validation
- [ ] Submit to API
- [ ] Navigate to dashboard on completion

### Week 4: Client Dashboard
- [ ] Build dashboard layout
- [ ] Health score gauge widget
- [ ] Status badge display
- [ ] Domain scores breakdown
- [ ] Top 3 wellness levers
- [ ] Quick actions

### Week 5: Daily Check-in
- [ ] Build check-in screen
- [ ] 4 emoji sliders (sleep, energy, mood, stress)
- [ ] Animated slider widget
- [ ] Submit to API
- [ ] Update health score display

### Week 6: Recommendations
- [ ] List recommendations screen
- [ ] Recommendation detail screen
- [ ] Markdown rendering
- [ ] Category filters
- [ ] Personalized recommendations

## 🐛 Debugging

### Common Issues

**API connection failed:**
- Check `API_URL` in `app_config.dart`
- Ensure backend is running
- For Android emulator, use `http://10.0.2.2:3000/api` instead of `localhost`

**Build runner fails:**
- Delete generated files: `rm -rf **/*.g.dart **/*.freezed.dart`
- Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Riverpod provider errors:**
- Ensure `ProviderScope` wraps your app in `main.dart`
- Check for circular dependencies

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Material 3 Guidelines](https://m3.material.io/)

## 📄 License

Proprietary - All rights reserved
