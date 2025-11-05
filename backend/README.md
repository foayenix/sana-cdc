# SANA Backend API

NestJS-based REST API for the SANA wellness platform.

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL (or Neon account)
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials

# Generate Prisma client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# Seed database with sample data
npm run prisma:seed
```

### Development

```bash
# Start development server (with hot reload)
npm run start:dev

# API will be available at http://localhost:3000/api
```

### Database Management

```bash
# Create a new migration
npm run prisma:migrate

# Open Prisma Studio (database GUI)
npm run prisma:studio

# Reset database (WARNING: deletes all data)
npx prisma migrate reset
```

## 📋 Available Scripts

- `npm run start` - Start production server
- `npm run start:dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm run test` - Run unit tests
- `npm run test:cov` - Run tests with coverage
- `npm run test:e2e` - Run end-to-end tests
- `npm run lint` - Lint code
- `npm run format` - Format code with Prettier

## 🏗️ Project Structure

```
src/
├── auth/              # Authentication (JWT, Google OAuth)
├── users/             # User profile management
├── questionnaire/     # Health questionnaire & score calculation
├── checkin/           # Daily check-ins
├── recommendations/   # Recommendation templates
├── practitioners/     # Practitioner profiles & verification
├── session-types/     # Session type management
├── appointments/      # Booking system
├── session-notes/     # SOAP format clinical notes
├── outcomes/          # Post-session outcome surveys
├── journal/           # Client journaling
├── payments/          # Stripe integration
├── sana-index/        # Practitioner credibility scoring
├── uploads/           # File upload handling (S3/R2)
├── notifications/     # Email & push notifications
├── prisma/            # Database service
├── app.module.ts      # Root module
└── main.ts            # Application entry point
```

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication:

- Access tokens: 15 minutes (short-lived for security)
- Refresh tokens: 7 days (for renewing access tokens)

### Making Authenticated Requests

```bash
# Login to get tokens
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Use access token in subsequent requests
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 📊 Database Schema

See `prisma/schema.prisma` for the complete database schema.

### Key Models

- **User**: Authentication and base user data
- **ClientProfile**: Health scores, questionnaire data, check-ins
- **PractitionerProfile**: Credentials, SANA Index, availability
- **Appointment**: Booking system
- **SessionNote**: Clinical notes (SOAP format)
- **ClientOutcome**: Post-session feedback
- **DailyCheckin**: Daily wellness tracking
- **RecommendationTemplate**: Evidence-based content

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:cov

# Run e2e tests
npm run test:e2e
```

## 🚢 Deployment

### Railway

1. Create new project on Railway
2. Add PostgreSQL database
3. Connect GitHub repository
4. Set environment variables
5. Deploy!

### Environment Variables for Production

```bash
DATABASE_URL="your-production-database-url"
JWT_SECRET="your-super-secret-key"
JWT_REFRESH_SECRET="your-refresh-secret"
STRIPE_SECRET_KEY="sk_live_..."
# ... see .env.example for full list
```

## 📚 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/google` - Google OAuth
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout

### Health Questionnaire
- `POST /api/questionnaire` - Submit questionnaire
- `GET /api/questionnaire/score` - Get health score
- `GET /api/questionnaire/levers` - Get top 3 wellness levers

### Daily Check-in
- `POST /api/checkin` - Submit daily check-in
- `GET /api/checkin/history?days=30` - Get check-in history
- `GET /api/checkin/completion-rate?days=30` - Get completion rate

### Recommendations
- `GET /api/recommendations` - List all templates
- `GET /api/recommendations/personalized` - Get personalized (requires auth)
- `GET /api/recommendations/:slug` - Get specific template
- `GET /api/recommendations/categories` - Get categories

### User Profile
- `GET /api/users/profile` - Get profile
- `PATCH /api/users/profile` - Update profile
- `DELETE /api/users/account` - Delete account

## 🔧 Troubleshooting

### Database Connection Issues

```bash
# Check if PostgreSQL is running
pg_isready

# Test connection string
psql "your-database-url"
```

### Prisma Client Errors

```bash
# Regenerate Prisma client
npm run prisma:generate

# Reset database and migrations
npx prisma migrate reset
```

## 📖 Documentation

- [NestJS Documentation](https://docs.nestjs.com/)
- [Prisma Documentation](https://www.prisma.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🤝 Support

For issues or questions, open a GitHub issue.
