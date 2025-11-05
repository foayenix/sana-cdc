# SANA Flutter App - Setup Guide

## Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK 3.0+
- Android Studio / Xcode
- Running backend API (see backend/README.md)

## Installation Steps

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Generate Code (IMPORTANT!)

The app uses code generation for models and JSON serialization. You MUST run this before running the app:

```bash
# Generate freezed models and JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Or use watch mode during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

This will generate the following files:
- `*.freezed.dart` - Freezed data classes
- `*.g.dart` - JSON serialization code

### 3. Configure API URL

Edit `lib/core/config/app_config.dart`:

```dart
static const String apiBaseUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://YOUR_BACKEND_URL/api');
```

**Important:** Use the correct URL for your device:
- **iOS Simulator:** `http://localhost:3000/api`
- **Android Emulator:** `http://10.0.2.2:3000/api`
- **Physical Device:** `http://YOUR_COMPUTER_IP:3000/api`

### 4. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices  # List devices
flutter run -d <device-id>

# Run on Chrome (web)
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                       # App entry point
├── app.dart                        # Root app widget
├── core/
│   ├── config/                     # Configuration
│   ├── constants/                  # Constants
│   ├── theme/                      # Theming
│   ├── router/                     # Navigation
│   └── widgets/                    # Reusable widgets
├── data/
│   ├── models/                     # Data models (with Freezed)
│   └── services/                   # API services
├── presentation/
│   ├── providers/                  # Riverpod providers
│   ├── screens/                    # App screens
│   └── widgets/                    # Feature widgets
```

## Available Screens

### Implemented ✅
- **Splash Screen** - Initial loading screen
- **Login Screen** - Email/password authentication
- **Signup Screen** - User registration with role selection
- **Questionnaire Screen** - 15-question health assessment
- **Dashboard Screen** - Health score and wellness overview
- **Check-in Screen** - Daily wellness tracking (4 emoji sliders)
- **Recommendations Screen** - Personalized wellness recommendations

### Placeholder 📝
- Profile Screen
- Find Practitioners Screen
- Appointments Screen
- Journal Screen

## Key Features

### Authentication Flow
1. Splash screen checks auth status
2. If not authenticated → Login
3. After login → Check if questionnaire completed
4. If not completed → Questionnaire
5. If completed → Dashboard

### Health Questionnaire
- Multi-step form (5 steps)
- 15 questions across 4 domains
- Submits to backend
- Calculates SANA Health Score (0-100)

### Dashboard
- Displays health score with animated gauge
- Shows status (RADIANT, THRIVING, BALANCED, etc.)
- Domain breakdown (Physical, Mental, Lifestyle, Social)
- Top 3 wellness levers
- Quick action cards

### Daily Check-in
- 4 emoji sliders (sleep, energy, mood, stress)
- Submits to backend
- Updates health score
- Shows updated score in dialog

## Troubleshooting

### Issue: Build errors about missing files

```bash
# Delete generated files
rm -rf **/*.freezed.dart **/*.g.dart

# Regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: API connection failed

1. Check backend is running (`npm run start:dev` in backend folder)
2. Verify API URL in `app_config.dart`
3. For Android emulator, use `10.0.2.2` instead of `localhost`
4. Check device/emulator can reach the backend

### Issue: Riverpod errors

1. Ensure `ProviderScope` wraps app in `main.dart`
2. Check for circular dependencies between providers
3. Try invalidating providers: `ref.invalidate(providerName)`

## Code Generation

### When to run code generation?

Run `flutter pub run build_runner build` after:
- Adding/modifying Freezed models
- Adding/modifying JSON serialization
- Pulling latest code

### Watch mode for development

```bash
# Automatically regenerates on file changes
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/health_score_test.dart

# Run with coverage
flutter test --coverage
```

## Building for Production

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

# Then archive in Xcode:
# 1. Open ios/Runner.xcworkspace
# 2. Product → Archive
```

## Next Steps

After getting the app running:

1. ✅ Complete backend setup (see backend/README.md)
2. ✅ Run code generation (`flutter pub run build_runner build`)
3. ✅ Test authentication flow (signup → login)
4. ✅ Complete health questionnaire
5. ✅ View dashboard with health score
6. ✅ Submit daily check-in
7. ✅ Browse recommendations

## Common Commands

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Clean build
flutter clean
flutter pub get

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

## Support

For issues:
- Check backend is running and accessible
- Verify code generation has been run
- Check Flutter and Dart SDK versions
- See troubleshooting section above
