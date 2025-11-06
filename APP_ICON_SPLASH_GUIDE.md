# App Icon & Splash Screen Guide

This guide explains how to generate and configure app icons and splash screens for SANA CDC.

## Prerequisites

```bash
# Install flutter_launcher_icons
flutter pub add --dev flutter_launcher_icons

# Install flutter_native_splash
flutter pub add --dev flutter_native_splash
```

## 1. App Icon Setup

### 1.1 Design Requirements

**Icon Specifications:**
- **Source Image**: 1024x1024 px PNG with transparency
- **iOS**: Requires icons from 20x20 to 1024x1024
- **Android**: Requires icons from 48x48 to 512x512
- **Background**: Use brand color #4A90E2 (SANA blue)
- **Design**: Simple, recognizable icon representing wellness/health

**Design Elements:**
- Logo: "SANA" text or stylized wellness symbol
- Colors: Primary blue (#4A90E2), white
- Style: Modern, clean, minimal

### 1.2 Create Icon Source

1. Create a 1024x1024 PNG icon at: `assets/images/app_icon.png`
2. Ensure the icon looks good at small sizes (48x48)
3. Use transparent background for iOS
4. Use colored background for Android

### 1.3 Configure flutter_launcher_icons

File: `flutter_launcher_icons.yaml`

```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"

  # Android adaptive icon
  adaptive_icon_foreground: "assets/images/app_icon_foreground.png"
  adaptive_icon_background: "#4A90E2"

  # iOS
  remove_alpha_ios: true

  # Web
  web:
    generate: true
    image_path: "assets/images/app_icon.png"
    background_color: "#4A90E2"
    theme_color: "#4A90E2"

  # Windows
  windows:
    generate: true
    image_path: "assets/images/app_icon.png"
    icon_size: 48

  # macOS
  macos:
    generate: true
    image_path: "assets/images/app_icon.png"
```

### 1.4 Generate Icons

```bash
# Generate all platform icons
flutter pub run flutter_launcher_icons
```

This will create:
- iOS icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Android icons in `android/app/src/main/res/mipmap-*/`
- Web icons in `web/icons/`

---

## 2. Splash Screen Setup

### 2.1 Design Requirements

**Splash Screen Specifications:**
- **Background Color**: #4A90E2 (SANA blue)
- **Logo**: SANA logo centered
- **Size**: 1242x2688 px (iPhone 12 Pro Max resolution)
- **Safe Area**: Keep important elements 10% from edges

**Design Elements:**
- SANA logo (white)
- Tagline: "Your Path to Wellness" (optional)
- Loading indicator (optional, added programmatically)

### 2.2 Create Splash Image

1. Create splash image at: `assets/images/splash_logo.png`
2. Logo should be ~400x400 px
3. Use transparent background
4. Logo color: White (#FFFFFF)

### 2.3 Configure flutter_native_splash

File: `flutter_native_splash.yaml`

```yaml
flutter_native_splash:
  # Background color (SANA blue)
  color: "#4A90E2"

  # Logo image
  image: assets/images/splash_logo.png

  # Branding image (bottom of screen)
  branding: assets/images/sana_wordmark.png
  branding_mode: bottom

  # Android 12+
  android_12:
    image: assets/images/splash_logo.png
    color: "#4A90E2"
    icon_background_color: "#4A90E2"

  # iOS
  ios: true

  # Web
  web: true

  # Fullscreen mode
  fullscreen: true

  # Info.plist customization (iOS)
  info_plist_files:
    - 'ios/Runner/Info.plist'
```

### 2.4 Generate Splash Screens

```bash
# Generate splash screens for all platforms
flutter pub run flutter_native_splash:create
```

This will create:
- iOS launch storyboard in `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- Android drawable resources in `android/app/src/main/res/drawable*/`
- Web splash screen in `web/splash/`

---

## 3. Brand Colors & Theme

**Primary Colors:**
```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const primary = Color(0xFF4A90E2); // SANA Blue
  static const secondary = Color(0xFF50C878); // Wellness Green
  static const background = Color(0xFFF8F9FA); // Light Gray
  static const surface = Color(0xFFFFFFFF); // White
  static const error = Color(0xFFE74C3C); // Error Red
  static const warning = Color(0xFFF39C12); // Warning Orange
  static const success = Color(0xFF27AE60); // Success Green

  // Text colors
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);
  static const textHint = Color(0xFFBDC3C7);
}
```

---

## 4. Asset Organization

```
assets/
├── images/
│   ├── app_icon.png                 # 1024x1024 app icon
│   ├── app_icon_foreground.png      # Android adaptive foreground
│   ├── splash_logo.png              # Splash screen logo
│   ├── sana_wordmark.png            # SANA wordmark for branding
│   ├── onboarding/                  # Onboarding images
│   ├── illustrations/               # App illustrations
│   └── placeholders/                # Placeholder images
├── fonts/                           # Custom fonts (if any)
└── icons/                           # Custom icons (if any)
```

---

## 5. Quick Design Tools

### Option 1: Figma (Recommended)
1. Use Figma template for app icons
2. Export at 1024x1024 PNG
3. Use Figma's iOS/Android export presets

### Option 2: Canva
1. Create 1024x1024 design
2. Use SANA brand colors
3. Export as PNG with transparent background

### Option 3: Adobe Illustrator/Photoshop
1. Create vector or raster at 1024x1024
2. Ensure crisp edges at all sizes
3. Export with and without transparency

### Option 4: Online Generators
- **AppIcon.co**: Upload 1024x1024, generates all sizes
- **MakeAppIcon.com**: Similar service
- **IconKitchen**: Android adaptive icon generator

---

## 6. Testing Icons & Splash

### iOS Testing
```bash
# Run on iOS simulator
flutter run -d iPhone

# Check different device sizes
# iPhone SE (small)
# iPhone 14 (medium)
# iPhone 14 Pro Max (large)
```

### Android Testing
```bash
# Run on Android emulator
flutter run -d emulator-5554

# Test adaptive icons
# Settings > Display > Icon shape
# Try: Circle, Squircle, Square
```

### Verification Checklist
- [ ] Icon looks clear at all sizes
- [ ] Icon background matches brand
- [ ] Splash screen displays correctly
- [ ] Splash doesn't flicker on launch
- [ ] Text is readable on splash
- [ ] Colors match brand guidelines
- [ ] Icons work on both light/dark system themes

---

## 7. App Store Assets

### iOS App Store Icons
- **Required**: 1024x1024 PNG (no transparency)
- Upload to App Store Connect
- Used for App Store listing

### Google Play Store Icon
- **Required**: 512x512 PNG (32-bit)
- Upload to Google Play Console
- Used for Play Store listing

### Feature Graphic (Android)
- **Size**: 1024x500 px
- Used at top of Play Store listing
- Include app name, tagline, key features

---

## 8. Troubleshooting

### Icons not updating?
```bash
# Clean build
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

### Splash screen not showing?
```bash
# Regenerate splash
flutter pub run flutter_native_splash:create
flutter clean
flutter run
```

### Android adaptive icon issues?
- Check `adaptive_icon_foreground` is correct size
- Ensure background color is solid (no transparency)
- Test on different launcher apps

### iOS icon rejection?
- Remove alpha channel: `remove_alpha_ios: true`
- Ensure 1024x1024 icon has no transparency
- Check icon doesn't include device bezels

---

## 9. Production Checklist

Before submitting to stores:

- [ ] App icon is 1024x1024 PNG
- [ ] iOS icon has no transparency
- [ ] Android icon has adaptive variant
- [ ] Splash screen background matches brand
- [ ] Splash logo is centered and sized correctly
- [ ] All icons generated successfully
- [ ] Tested on multiple device sizes
- [ ] Icons look good in both themes (light/dark)
- [ ] No copyright issues with images
- [ ] Assets compressed for optimal size

---

## 10. Brand Guidelines Summary

**SANA Brand Identity:**
- **Primary Color**: #4A90E2 (Blue) - Trust, professionalism, calm
- **Secondary Color**: #50C878 (Green) - Wellness, growth, healing
- **Typography**: Clean, modern, readable
- **Imagery**: Wellness-focused, diverse, authentic
- **Tone**: Professional, caring, empowering

**Icon Design Principles:**
- Simple and recognizable
- Scalable to small sizes
- Unique and memorable
- Represents wellness/health
- Consistent with brand

---

**Last Updated**: November 2025
**Version**: 1.0.0
