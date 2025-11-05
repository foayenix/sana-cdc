# SANA - Wellness Platform MVP

## 🎯 Project Overview

SANA is a dual-sided wellness platform connecting clients with credible CAM (Complementary and Alternative Medicine) practitioners while tracking wellness outcomes.

**Timeline:** 6 months
**Budget:** £50,000
**Goal:** 100 paying practitioners, £60k ARR

## 🏗️ Architecture

```
sana-cdc/
├── backend/          # NestJS API (Node.js + TypeScript)
├── frontend/         # Flutter Mobile App
└── docs/             # Documentation
```

### Tech Stack

**Backend:**
- NestJS (TypeScript)
- PostgreSQL + Prisma ORM
- JWT Authentication
- Stripe Payments
- AWS S3 / Cloudflare R2
- SendGrid / AWS SES

**Frontend:**
- Flutter 3.x
- Riverpod (State Management)
- go_router (Navigation)
- Material 3 Design

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL (or Neon account)
- Flutter SDK 3.x
- Stripe account
- AWS S3 or Cloudflare R2 account

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials

# Generate Prisma client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# Seed database (optional)
npm run prisma:seed

# Start development server
npm run start:dev
```

The API will be available at `http://localhost:3000/api`

### Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📊 Database Schema

See `backend/prisma/schema.prisma` for the complete schema.

**Key Models:**
- `User` - Authentication and user management
- `ClientProfile` - Client health data and scores
- `PractitionerProfile` - Practitioner credentials and SANA Index
- `Appointment` - Booking system
- `SessionNote` - SOAP format clinical notes
- `ClientOutcome` - Post-session outcomes
- `DailyCheckin` - Daily wellness tracking

## 🔑 Environment Variables

### Backend (.env)

```bash
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/sana_dev"

# JWT
JWT_SECRET="your-secret-key"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_SECRET="your-refresh-secret"
JWT_REFRESH_EXPIRES_IN="7d"

# Google OAuth
GOOGLE_CLIENT_ID="your-client-id"
GOOGLE_CLIENT_SECRET="your-client-secret"

# Stripe
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_PUBLISHABLE_KEY="pk_test_..."

# AWS S3
AWS_REGION="eu-west-2"
AWS_ACCESS_KEY_ID="your-key"
AWS_SECRET_ACCESS_KEY="your-secret"
AWS_S3_BUCKET="sana-uploads"

# SendGrid
SENDGRID_API_KEY="SG...."
SENDGRID_FROM_EMAIL="noreply@sana.health"

# Application
NODE_ENV="development"
PORT=3000
API_URL="http://localhost:3000"
FRONTEND_URL="http://localhost:8080"
```

## 📚 API Documentation

### Authentication Endpoints

```
POST   /api/auth/register      # Register new user
POST   /api/auth/login         # Login with email/password
POST   /api/auth/google        # Google OAuth login
POST   /api/auth/refresh       # Refresh access token
GET    /api/auth/me            # Get current user
POST   /api/auth/logout        # Logout
```

### Health Questionnaire & Score

```
POST   /api/questionnaire      # Submit questionnaire
GET    /api/questionnaire/score    # Get current health score
GET    /api/questionnaire/levers   # Get top 3 wellness levers
```

### Daily Check-in

```
POST   /api/checkin            # Submit daily check-in
GET    /api/checkin/history    # Get check-in history
GET    /api/checkin/completion-rate  # Get completion rate
```

### User Profile

```
GET    /api/users/profile      # Get user profile
PATCH  /api/users/profile      # Update profile
DELETE /api/users/account      # Delete account
```

## 🧮 Core Algorithms

### SANA Health Score (0-100)

Calculated from 15 health questionnaire questions across 4 domains:

- **Physical** (25 points): Sleep, pain, energy
- **Mental** (25 points): Mood, anxiety, stress
- **Lifestyle** (25 points): Exercise, diet, alcohol
- **Social** (25 points): Connection, satisfaction, work-life balance

**Status Levels:**
- 91-100: RADIANT
- 76-90: THRIVING
- 61-75: BALANCED
- 41-60: REBUILDING
- 0-40: NEEDS_SUPPORT

**Daily Updates:** Score is updated via weighted moving average (90% current, 10% daily check-in) for gradual, meaningful changes.

See implementation: `backend/src/questionnaire/health-score.calculator.ts`

### SANA Index (Practitioner Credibility: 0-100)

- **Credentials** (30 points): Degree, registration, insurance
- **Experience** (30 points): Years of practice
- **Outcomes** (40 points): Client improvement rate (min. 20 outcomes)

**Improvement Rate:**
- 85%+: 40 points
- 70-84%: 30 points
- 50-69%: 20 points
- <50%: 10 points

## 🗓️ Development Timeline

### Phase 1: Client Foundation (Month 1) ✅ IN PROGRESS
- [x] Backend setup with NestJS
- [x] Database schema with Prisma
- [x] JWT authentication
- [x] Health questionnaire API
- [x] Health score calculation
- [x] Daily check-in system
- [ ] Recommendation templates
- [ ] Flutter app setup
- [ ] Authentication screens
- [ ] Questionnaire screens
- [ ] Dashboard screen
- [ ] Check-in widget

### Phase 2: Practitioner Foundation (Month 2)
- [ ] Practitioner signup & profile
- [ ] Credential upload (S3/R2)
- [ ] Manual verification workflow
- [ ] Availability management
- [ ] SANA Index calculation
- [ ] Public practitioner profiles

### Phase 3: Booking & Payments (Month 3)
- [ ] Practitioner search
- [ ] Booking flow
- [ ] Stripe integration
- [ ] Stripe Connect (practitioner payouts)
- [ ] Calendar invites

### Phase 4: Session Management (Month 4)
- [ ] Appointment management
- [ ] Session notes (SOAP format)
- [ ] Client journal
- [ ] Post-session outcome surveys

### Phase 5: Polish (Month 5)
- [ ] Progress tracking graphs
- [ ] Push notifications (Firebase)
- [ ] Email notifications
- [ ] Profile management
- [ ] Basic admin dashboard

### Phase 6: Launch Prep (Month 6)
- [ ] Security audit
- [ ] Testing (unit, integration, e2e)
- [ ] Performance optimization
- [ ] App store preparation

## 🔒 Security Features

- Bcrypt password hashing (10 rounds)
- JWT with short-lived access tokens (15 min)
- Refresh tokens (7 days)
- Rate limiting on auth endpoints
- Role-based access control (RBAC)
- Input validation with class-validator
- HTTPS only in production
- Stripe webhook signature verification

## 🧪 Testing

```bash
# Backend
cd backend

# Run unit tests
npm test

# Run tests with coverage
npm run test:cov

# Run e2e tests
npm run test:e2e
```

```bash
# Flutter
cd frontend

# Run widget tests
flutter test

# Run integration tests
flutter test integration_test
```

## 📦 Deployment

### Backend (Railway / Render)

1. Connect GitHub repository
2. Set environment variables
3. Deploy main branch
4. Run migrations: `npm run prisma:migrate`

### Frontend (App Stores)

```bash
cd frontend

# Build for iOS
flutter build ios --release

# Build for Android
flutter build apk --release
```

## 📝 Contributing

This is a solo founder project for MVP. External contributions will be considered post-launch.

## 📄 License

Proprietary - All rights reserved

## 🤝 Support

For issues or questions, contact: [your-email]

---

**Built with ❤️ for the wellness community**
