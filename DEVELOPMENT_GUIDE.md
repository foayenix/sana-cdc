# SANA MVP - Development Guide

## 📋 Project Status

**Current Phase:** Phase 1 - Foundation & Client Core (Week 1-4)

### ✅ Completed

**Backend:**
- [x] NestJS project initialized
- [x] Prisma schema with all models
- [x] JWT authentication (email/password + Google OAuth)
- [x] User management endpoints
- [x] Health questionnaire API
- [x] Health score calculation algorithm
- [x] Daily check-in system
- [x] Recommendations module
- [x] Database migrations ready
- [x] Seed data for recommendations

**Frontend:**
- [x] Flutter project initialized
- [x] Project structure (clean architecture)
- [x] Core configuration (AppConfig, constants)
- [x] Theme system (Material 3, colors, typography)
- [x] Basic routing (GoRouter)
- [x] Dependencies configured

**Documentation:**
- [x] Main README
- [x] Backend README
- [x] Frontend README
- [x] Development Guide

### 🚧 In Progress

- [ ] Authentication screens (Flutter)
- [ ] Questionnaire screens (Flutter)
- [ ] Dashboard screen (Flutter)
- [ ] API service integration (Flutter)

### 📅 Next Steps

See "Phase 1 Continuation" below.

---

## 🔧 Development Setup

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your database credentials

# For local development, use PostgreSQL or Neon (free tier)
# DATABASE_URL="postgresql://user:password@localhost:5432/sana_dev"

# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# Seed database
npm run prisma:seed

# Start development server
npm run start:dev
```

**Backend will run on:** `http://localhost:3000/api`

**Test endpoints:**
```bash
# Health check
curl http://localhost:3000/api/health

# Get API info
curl http://localhost:3000/api

# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "role": "CLIENT"
  }'
```

### 2. Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Run code generation (when needed)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Or run on specific device
flutter run -d chrome  # Web
flutter run -d <device-id>  # iOS/Android
```

**Important:** Update `API_URL` in `lib/core/config/app_config.dart`:
- iOS Simulator: `http://localhost:3000/api`
- Android Emulator: `http://10.0.2.2:3000/api`
- Physical device: `http://YOUR_COMPUTER_IP:3000/api`

---

## 📂 Project Organization

### Backend Structure

```
backend/src/
├── auth/              ✅ JWT + Google OAuth (DONE)
├── users/             ✅ User management (DONE)
├── questionnaire/     ✅ Health score calculation (DONE)
├── checkin/           ✅ Daily check-ins (DONE)
├── recommendations/   ✅ Templates & personalization (DONE)
├── practitioners/     📝 TO IMPLEMENT (Phase 2)
├── session-types/     📝 TO IMPLEMENT (Phase 3)
├── appointments/      📝 TO IMPLEMENT (Phase 3)
├── session-notes/     📝 TO IMPLEMENT (Phase 4)
├── outcomes/          📝 TO IMPLEMENT (Phase 4)
├── journal/           📝 TO IMPLEMENT (Phase 4)
├── payments/          📝 TO IMPLEMENT (Phase 3)
├── sana-index/        📝 TO IMPLEMENT (Phase 2)
├── uploads/           📝 TO IMPLEMENT (Phase 2)
└── notifications/     📝 TO IMPLEMENT (Phase 5)
```

### Frontend Structure

```
frontend/lib/
├── core/              ✅ Config, theme, router (DONE)
├── data/              📝 TO IMPLEMENT (models, repos, services)
├── presentation/      📝 TO IMPLEMENT (screens, widgets, providers)
└── features/          📝 ALTERNATIVE (feature-first organization)
```

---

## 🎯 Phase 1 Continuation (Weeks 1-4)

### Week 1: Authentication Flow

**Backend (already done):**
- ✅ Register, login, Google OAuth endpoints
- ✅ JWT token generation and refresh
- ✅ User profile endpoint

**Frontend (to implement):**

1. **Create data models:**
   - `lib/data/models/user.dart`
   - `lib/data/models/auth_response.dart`

2. **Create API service:**
   - `lib/data/services/api_service.dart` (Dio setup)
   - `lib/data/services/auth_service.dart` (API calls)

3. **Create repository:**
   - `lib/data/repositories/auth_repository.dart`

4. **Create providers:**
   - `lib/presentation/providers/auth_provider.dart`

5. **Build screens:**
   - `lib/presentation/screens/auth/login_screen.dart`
   - `lib/presentation/screens/auth/signup_screen.dart`
   - `lib/presentation/screens/auth/role_selection_screen.dart`

6. **Build widgets:**
   - `lib/core/widgets/custom_button.dart`
   - `lib/core/widgets/custom_text_field.dart`
   - `lib/core/widgets/loading_dialog.dart`

**Testing:**
```bash
# Backend
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Frontend
# Login with test@example.com / password123
# Should navigate to questionnaire if not completed
# Should navigate to dashboard if completed
```

---

### Week 2: Health Questionnaire

**Backend (already done):**
- ✅ POST /api/questionnaire
- ✅ GET /api/questionnaire/score
- ✅ Health score algorithm

**Frontend (to implement):**

1. **Create models:**
   - `lib/data/models/questionnaire_response.dart`
   - `lib/data/models/health_score.dart`

2. **Create service & repository:**
   - `lib/data/services/questionnaire_service.dart`
   - `lib/data/repositories/questionnaire_repository.dart`

3. **Create provider:**
   - `lib/presentation/providers/questionnaire_provider.dart`

4. **Build questionnaire screen:**
   - Multi-step form (15 questions)
   - 4 domain sections (Physical, Mental, Lifestyle, Social)
   - Progress indicator
   - Validation
   - Submit button

5. **Question widgets:**
   - Slider widget (for sleep hours, pain level)
   - Rating widget (1-5 scale)
   - Multiple choice widget

**UI Flow:**
```
1. Introduction screen → "Let's understand your current wellness"
2. Physical domain (4 questions) → Progress: 4/15
3. Mental domain (3 questions) → Progress: 7/15
4. Lifestyle domain (3 questions) → Progress: 10/15
5. Social domain (3 questions) → Progress: 13/15
6. Additional context (2 questions) → Progress: 15/15
7. Review & Submit
8. Loading (calculating score)
9. Navigate to Dashboard with score
```

---

### Week 3: Client Dashboard

**Backend (already done):**
- ✅ GET /api/auth/me (includes health score)
- ✅ GET /api/questionnaire/levers
- ✅ GET /api/recommendations/personalized

**Frontend (to implement):**

1. **Build dashboard screen:**
   - Welcome message with user name
   - Health score gauge widget
   - Status badge
   - Domain scores breakdown (4 cards)
   - Top 3 wellness levers
   - Quick actions (check-in, journal, find practitioner)
   - Upcoming appointments (Phase 3)

2. **Create widgets:**
   - `lib/presentation/widgets/health_score_gauge.dart`
     - Circular progress indicator
     - Animated to current score
     - Color based on status
   - `lib/presentation/widgets/status_badge.dart`
   - `lib/presentation/widgets/domain_score_card.dart`
   - `lib/presentation/widgets/lever_card.dart`

3. **Create providers:**
   - `lib/presentation/providers/user_provider.dart`
   - `lib/presentation/providers/health_score_provider.dart`

**Dashboard Layout:**
```
┌─────────────────────────────────────┐
│  Welcome back, [Name]!    [Profile] │
│                                      │
│  ┌─────────────────────────────┐   │
│  │   SANA HEALTH SCORE         │   │
│  │        [Gauge: 73]          │   │
│  │   Status: THRIVING 🌱       │   │
│  └─────────────────────────────┘   │
│                                      │
│  Your Wellness Domains              │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────┐│
│  │Phys. │ │Mental│ │Life. │ │Soc.││
│  │ 18/25│ │ 20/25│ │ 19/25│ │16/25││
│  └──────┘ └──────┘ └──────┘ └────┘│
│                                      │
│  Your Top 3 Wellness Levers         │
│  • Strengthen social connections    │
│  • Improve sleep quality            │
│  • Manage stress levels             │
│                                      │
│  Daily Check-In (Quick!)            │
│  [Tap to submit today's check-in]  │
│                                      │
│  Quick Actions                      │
│  [Find Practitioner] [Journal]     │
└─────────────────────────────────────┘
```

---

### Week 4: Daily Check-in

**Backend (already done):**
- ✅ POST /api/checkin
- ✅ GET /api/checkin/history
- ✅ Updates health score

**Frontend (to implement):**

1. **Create models:**
   - `lib/data/models/daily_checkin.dart`

2. **Create service & repository:**
   - `lib/data/services/checkin_service.dart`
   - `lib/data/repositories/checkin_repository.dart`

3. **Build check-in screen:**
   - 4 emoji sliders (interactive!)
   - Submit button
   - Confirmation animation

4. **Create emoji slider widget:**
   - `lib/presentation/widgets/emoji_slider.dart`
   - Tap or drag to select 1-5
   - Animated emoji faces
   - Smooth transitions

5. **Create provider:**
   - `lib/presentation/providers/checkin_provider.dart`

**Emoji Slider Design:**

```
😴 Sleep Quality
💤 → 😴 → 😌 → 🛌 → ✨
[────●───────────────]
     2

⚡ Energy Level
🔋 → 🪫 → ⚡ → 🔥 → 💪
[──────────●─────────]
          3

😊 Mood
😢 → 😕 → 😐 → 🙂 → 😄
[──────────────────●─]
                  5

😰 Stress Level
😌 → 🙂 → 😐 → 😟 → 😰
[────●───────────────]
     2
```

**Check-in Flow:**
```
1. Tap "Daily Check-In" from dashboard
2. Screen with 4 emoji sliders
3. Adjust each slider
4. Tap "Submit"
5. Loading animation
6. Success message: "Check-in recorded! +3 to your score"
7. Navigate back to dashboard (score updates)
```

---

### Week 5-6: Recommendations

**Backend (already done):**
- ✅ GET /api/recommendations (all templates)
- ✅ GET /api/recommendations/personalized
- ✅ GET /api/recommendations/:slug
- ✅ 3 seed templates (sleep, stress, energy)

**Frontend (to implement):**

1. **Create models:**
   - `lib/data/models/recommendation.dart`

2. **Build screens:**
   - `lib/presentation/screens/client/recommendations_screen.dart`
   - `lib/presentation/screens/client/recommendation_detail_screen.dart`

3. **Build widgets:**
   - `lib/presentation/widgets/recommendation_card.dart`
   - Category filter chips
   - Markdown renderer for content
   - Citation links

**TODO:** Add 47 more recommendation templates to seed.ts

---

## 🔬 Testing Strategy

### Backend Tests

```bash
cd backend

# Health score algorithm
npm run test -- health-score.calculator.spec.ts

# Auth endpoints
npm run test:e2e -- auth.e2e-spec.ts
```

### Frontend Tests

```bash
cd frontend

# Widget tests
flutter test test/widget/health_score_gauge_test.dart

# Integration test
flutter test integration_test/auth_flow_test.dart
```

---

## 🚀 Phase 2 Preview (Weeks 5-8)

After completing Phase 1, you'll implement:

1. **Practitioner Signup & Profile**
   - Backend: Create practitioner endpoints
   - Frontend: Practitioner profile form
   - File upload for credentials

2. **Credential Verification**
   - Backend: File upload to S3/R2
   - Backend: Admin verification dashboard
   - Frontend: Upload UI with progress

3. **Availability Management**
   - Backend: Recurring schedule endpoints
   - Frontend: Calendar-based availability editor

4. **SANA Index**
   - Backend: Calculation service
   - Frontend: Display on practitioner profiles

---

## 🛠️ Useful Commands

### Backend

```bash
npm run start:dev           # Start dev server
npm run prisma:studio       # Open database GUI
npm run prisma:migrate      # Create new migration
npm run test                # Run tests
npm run lint                # Lint code
```

### Frontend

```bash
flutter run                 # Run app
flutter test                # Run tests
flutter analyze             # Analyze code
flutter pub run build_runner build  # Generate code
flutter build apk           # Build Android APK
flutter build ios           # Build iOS app
```

### Database

```bash
# Reset database (WARNING: deletes all data)
cd backend
npx prisma migrate reset

# Create a new migration
npx prisma migrate dev --name add_new_field

# View database
npm run prisma:studio
```

---

## 🐛 Troubleshooting

### Backend won't start

```bash
# Check PostgreSQL is running
pg_isready

# Delete node_modules and reinstall
rm -rf node_modules
npm install

# Regenerate Prisma client
npm run prisma:generate
```

### Frontend build issues

```bash
# Clean build
flutter clean
flutter pub get

# Delete generated files
rm -rf **/*.g.dart **/*.freezed.dart
flutter pub run build_runner build --delete-conflicting-outputs
```

### API connection failed (Flutter)

- Android Emulator: Use `http://10.0.2.2:3000/api`
- iOS Simulator: Use `http://localhost:3000/api`
- Physical device: Use `http://YOUR_IP:3000/api`

---

## 📖 Key Resources

- **NestJS Docs:** https://docs.nestjs.com/
- **Prisma Docs:** https://www.prisma.io/docs/
- **Flutter Docs:** https://docs.flutter.dev/
- **Riverpod Docs:** https://riverpod.dev/
- **Material 3:** https://m3.material.io/

---

## 🎯 Success Criteria for Phase 1

**Week 4 Demo should show:**

1. ✅ User can sign up (email/password)
2. ✅ User can login
3. ✅ User completes 15-question health questionnaire
4. ✅ Health score is calculated (0-100) with status
5. ✅ Dashboard shows health score with gauge
6. ✅ Dashboard shows domain breakdown
7. ✅ Dashboard shows top 3 wellness levers
8. ✅ User can submit daily check-in (4 emoji sliders)
9. ✅ Health score updates after check-in
10. ✅ User can view recommendations
11. ✅ Personalized recommendations based on lowest domain

**Backend API should have:**
- ✅ All Phase 1 endpoints functional
- ✅ JWT auth with refresh tokens
- ✅ Health score algorithm working correctly
- ✅ Data persisted to PostgreSQL

**Code Quality:**
- ✅ Clean, commented code
- ✅ Proper error handling
- ✅ Form validation
- ✅ Loading states
- ✅ Responsive UI

---

## 📝 Notes

- This is a 6-month MVP - prioritize working functionality over perfection
- Follow "build the boring version first" - no premature optimization
- Security and payment handling (Phase 3) must be rock-solid
- Document decisions in code comments
- Commit frequently with clear messages

**Questions?** Refer to the specification in the main README or reach out for clarification.

---

**Happy coding! Let's build something great! 🚀**
