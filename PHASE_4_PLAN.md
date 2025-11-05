# Phase 4: Advanced Features & Platform Optimization

**Status:** Planning 🎯
**Branch:** TBD (will create new branch)
**Target:** Enhanced user experience, platform growth, operational excellence

---

## 🎯 Executive Summary

Phase 4 focuses on **platform maturity** and **user engagement** by adding features that increase retention, improve discoverability, and provide actionable insights. This phase transforms SANA from an MVP into a **growth-ready platform**.

**Key Objectives:**
- 📧 **Improve Retention** - Automated notifications and reminders
- 📊 **Data-Driven Insights** - Analytics dashboards for all users
- ⭐ **Build Trust** - Reviews and ratings system
- 🔍 **Enhance Discovery** - Advanced search and recommendations
- 💬 **Enable Communication** - In-app messaging
- 📱 **Mobile Excellence** - Push notifications and offline support

---

## 📦 Phase 4 Modules Overview

### Module 1: Notifications & Reminders System ⚡ HIGH PRIORITY
**Impact:** Reduces no-shows, improves engagement
**Complexity:** Medium

**Features:**
- Email notifications (appointment confirmations, reminders, cancellations)
- SMS notifications (optional, via Twilio)
- Push notifications (Firebase Cloud Messaging)
- Customizable notification preferences
- Automated reminder schedule (24h, 1h before appointment)
- Practitioner notifications (new bookings, cancellations)
- Admin notifications (new practitioner signups, verification requests)

**Technical Stack:**
- Backend: SendGrid/AWS SES for email, Twilio for SMS
- Frontend: Firebase Cloud Messaging
- Queue system: Bull/BullMQ for scheduled jobs
- Templates: Handlebars/EJS for email templates

**Deliverables:**
- Email service with templates
- SMS service integration
- Push notification service
- Notification preferences screen
- Scheduled reminder jobs
- Admin notification center

---

### Module 2: Analytics & Reporting Dashboard 📊 HIGH PRIORITY
**Impact:** Enables data-driven decisions
**Complexity:** Medium-High

**Features:**

**For Practitioners:**
- Appointment statistics (total, completed, cancelled, no-shows)
- Revenue analytics (total earnings, by month, by session type)
- Client retention metrics
- Outcome score trends over time
- Session type performance comparison
- Booking conversion rates
- Average session rating
- Peak booking times/days

**For Clients:**
- Health score trends over time
- Appointment history summary
- Outcome progress tracking
- Check-in consistency metrics
- Recommendations completion rate
- Favorite practitioners

**For Admins:**
- Platform-wide statistics
- User growth metrics
- Revenue dashboard
- Practitioner performance leaderboard
- Geographic distribution
- Popular session types
- Verification pipeline status

**Technical Stack:**
- Charts: Recharts/fl_chart (Flutter)
- Date range selectors
- Export to PDF/CSV
- Real-time updates
- Caching for performance

**Deliverables:**
- Practitioner analytics screen
- Client progress dashboard
- Admin analytics dashboard
- Export functionality
- Date range filters

---

### Module 3: Reviews & Ratings System ⭐ HIGH PRIORITY
**Impact:** Builds trust, improves quality
**Complexity:** Medium

**Features:**
- 5-star rating system for appointments
- Written reviews (optional)
- Practitioner response to reviews
- Review moderation (admin)
- Average rating display on profiles
- Recent reviews showcase
- Report inappropriate reviews
- Verified booking badge
- Helpful review voting

**Technical Stack:**
- Review service with CRUD operations
- Moderation queue
- Sentiment analysis (optional, AWS Comprehend)
- Spam detection

**Deliverables:**
- Review model and service
- Rating component
- Reviews list screen
- Practitioner profile integration
- Admin moderation interface
- Email notification for new reviews

**Business Rules:**
- Only completed appointments can be reviewed
- One review per appointment
- Reviews submitted within 7 days of completion
- Practitioners can respond once
- Reviews cannot be edited after submission
- 24-hour moderation window

---

### Module 4: Advanced Search & Filtering 🔍 MEDIUM PRIORITY
**Impact:** Improves practitioner discoverability
**Complexity:** Medium

**Features:**
- Multi-criteria filtering (specialties, price range, availability, rating, location)
- Sort options (price, rating, experience, availability)
- Distance-based search (if location provided)
- "Available today" filter
- Session type filtering
- Price range slider
- Rating filter (4+ stars, 3+ stars)
- Search by keyword (bio, specialties)
- Save search preferences
- Search history
- Recommended practitioners (ML-based, future)

**Technical Stack:**
- Elasticsearch/Algolia for fast search (optional)
- Geolocation services
- Filter UI components
- Search result caching

**Deliverables:**
- Advanced search screen
- Filter drawer/modal
- Sort functionality
- Practitioner search service enhancements
- Search results optimization
- "Available now" indicator

---

### Module 5: In-App Messaging System 💬 MEDIUM PRIORITY
**Impact:** Improves communication, reduces friction
**Complexity:** High

**Features:**
- Real-time messaging between client and practitioner
- Message history
- Read receipts
- Typing indicators
- File/image attachments
- Automated messages (booking confirmations, reminders)
- Push notifications for new messages
- Archived conversations
- Message search
- Blocked users

**Technical Stack:**
- WebSockets (Socket.io) or Firebase Realtime Database
- Message queue for reliability
- File upload to S3
- Push notifications integration

**Deliverables:**
- Message model and service
- Chat screen (Flutter)
- Message list screen
- Real-time message updates
- Notification integration
- File upload handling
- Admin moderation tools

**Business Rules:**
- Messaging only available between booked clients and practitioners
- First message sent after booking confirmation
- Messages archived 90 days after appointment completion
- Inappropriate content reporting
- Admin can view/moderate conversations

---

### Module 6: Appointment Calendar & Scheduling Enhancements 📅 MEDIUM PRIORITY
**Impact:** Better practitioner workflow
**Complexity:** Medium

**Features:**

**For Practitioners:**
- Visual calendar view (month/week/day)
- Drag-and-drop rescheduling
- Bulk availability updates
- Recurring availability patterns
- Time-off management
- Availability templates (e.g., "Summer schedule")
- Waitlist management
- Appointment templates (pre-filled notes)
- Quick actions (confirm, cancel, complete)

**For Clients:**
- Calendar view of their appointments
- Add to personal calendar (Google/Apple)
- Recurring appointment booking
- Favorite practitioners quick booking

**Technical Stack:**
- Calendar library (table_calendar)
- iCal/ICS generation
- Calendar sync APIs

**Deliverables:**
- Practitioner calendar screen
- Availability management screen
- Calendar export functionality
- Drag-and-drop rescheduling
- Time-off request form
- Client calendar view

---

### Module 7: Payment & Billing Enhancements 💳 LOW PRIORITY
**Impact:** Improves financial operations
**Complexity:** Medium

**Features:**
- Payment history with filters
- Invoice generation and download
- Refund request tracking
- Payment methods management
- Subscription packages (future)
- Practitioner payout dashboard
- Stripe Connect integration (practitioner payouts)
- Payment receipts via email
- Failed payment retry
- Payment dispute handling

**Technical Stack:**
- Stripe Connect for payouts
- PDF generation for invoices
- Email with attachments

**Deliverables:**
- Payment history screen (enhanced)
- Invoice generation service
- Practitioner payout screen
- Stripe Connect integration
- Receipt email templates

---

### Module 8: Admin Dashboard & Platform Management 🔧 MEDIUM PRIORITY
**Impact:** Operational efficiency
**Complexity:** Medium-High

**Features:**

**User Management:**
- User list with search/filter
- User detail view
- Suspend/activate accounts
- Impersonate user (for support)
- Export user data

**Practitioner Verification:**
- Verification queue with filters
- Document viewer
- Approve/reject with notes
- Verification history
- Automated checks

**Content Moderation:**
- Reviews moderation queue
- Reported content review
- User reports dashboard

**Platform Settings:**
- Email templates editor
- Notification settings
- Feature flags
- Maintenance mode

**Analytics:**
- Real-time dashboard
- User growth charts
- Revenue reports
- System health monitoring

**Technical Stack:**
- Admin-specific routes
- Role-based access control
- Audit logging
- Dashboard components

**Deliverables:**
- Admin login and dashboard
- User management screens
- Verification workflow
- Moderation interface
- Platform settings
- Analytics dashboard

---

### Module 9: Enhanced User Profiles 👤 LOW PRIORITY
**Impact:** Richer user experience
**Complexity:** Low-Medium

**Features:**

**For Practitioners:**
- Video introduction (upload)
- Detailed bio with formatting
- Specialization badges
- Years of experience calculation
- Professional achievements
- Availability at a glance
- Session type showcase
- Client testimonials highlight
- Social media links

**For Clients:**
- Health goals tracking
- Wellness journal
- Progress photos (private)
- Preferred communication method
- Emergency contact
- Health conditions (optional)
- Preferences (session types, practitioner traits)

**Deliverables:**
- Enhanced profile screens
- Video upload functionality
- Rich text editor for bio
- Profile completion indicator
- Badges system

---

### Module 10: Platform Optimization & Performance 🚀 ONGOING
**Impact:** Better user experience
**Complexity:** Varies

**Features:**
- API response caching
- Database query optimization
- Image optimization and CDN
- Lazy loading
- Pagination improvements
- API rate limiting
- Error tracking (Sentry)
- Performance monitoring (New Relic/DataDog)
- Database indexing
- Code splitting (frontend)
- Service worker for PWA
- Offline support

**Deliverables:**
- Performance benchmarks
- Optimization implementation
- Monitoring dashboards
- Error tracking setup

---

## 📋 Implementation Priority

### Phase 4A: Foundation (Weeks 1-3)
**Focus:** Essential engagement features

1. ✅ **Notifications & Reminders** (Module 1)
   - Email service setup
   - Notification templates
   - Scheduled reminder jobs
   - Push notifications (basic)

2. ✅ **Reviews & Ratings** (Module 3)
   - Review model and service
   - Rating component
   - Reviews display on profile
   - Basic moderation

**Outcome:** Reduced no-shows, trust building begins

---

### Phase 4B: Insights (Weeks 4-6)
**Focus:** Data-driven decision making

3. ✅ **Analytics Dashboard** (Module 2)
   - Practitioner analytics
   - Client progress tracking
   - Admin platform analytics
   - Export functionality

4. ✅ **Admin Dashboard** (Module 8 - Part 1)
   - Admin login
   - User management
   - Basic verification workflow
   - Platform statistics

**Outcome:** All users have actionable insights

---

### Phase 4C: Discovery (Weeks 7-8)
**Focus:** Better matching

5. ✅ **Advanced Search** (Module 4)
   - Multi-criteria filters
   - Sort options
   - Availability filtering
   - Search optimization

6. ✅ **Enhanced Profiles** (Module 9 - Part 1)
   - Richer practitioner profiles
   - Badges and achievements
   - Client preferences

**Outcome:** Better practitioner discovery

---

### Phase 4D: Communication (Weeks 9-11)
**Focus:** Real-time interaction

7. ✅ **In-App Messaging** (Module 5)
   - Real-time chat
   - Message history
   - Push notifications
   - File sharing

8. ✅ **Appointment Enhancements** (Module 6)
   - Visual calendar
   - Availability templates
   - Time-off management

**Outcome:** Seamless communication

---

### Phase 4E: Financial (Weeks 12-13)
**Focus:** Better financial operations

9. ✅ **Payment Enhancements** (Module 7)
   - Invoice generation
   - Payout dashboard
   - Stripe Connect

10. ✅ **Platform Optimization** (Module 10)
    - Performance improvements
    - Monitoring setup
    - Error tracking

**Outcome:** Professional financial operations

---

## 🏗️ Technical Architecture

### Backend Changes

**New Services:**
```
backend/src/
├── notifications/
│   ├── notifications.service.ts (email, SMS, push)
│   ├── notifications.controller.ts
│   ├── notification-templates/
│   └── notifications.module.ts
├── reviews/
│   ├── reviews.service.ts
│   ├── reviews.controller.ts
│   └── reviews.module.ts
├── analytics/
│   ├── analytics.service.ts
│   ├── analytics.controller.ts
│   └── analytics.module.ts
├── messaging/
│   ├── messaging.gateway.ts (WebSocket)
│   ├── messaging.service.ts
│   ├── messaging.controller.ts
│   └── messaging.module.ts
├── admin/
│   ├── admin.service.ts
│   ├── admin.controller.ts
│   └── admin.module.ts
└── jobs/
    ├── reminder.job.ts
    ├── cleanup.job.ts
    └── jobs.module.ts
```

**New Dependencies:**
```json
{
  "@nestjs/bull": "^10.0.0",
  "bull": "^4.11.0",
  "@nestjs-modules/mailer": "^1.9.0",
  "nodemailer": "^6.9.0",
  "handlebars": "^4.7.8",
  "@nestjs/websockets": "^10.0.0",
  "@nestjs/platform-socket.io": "^10.0.0",
  "socket.io": "^4.6.0",
  "twilio": "^4.18.0",
  "firebase-admin": "^11.11.0",
  "@sentry/node": "^7.80.0"
}
```

**New Database Tables:**
```prisma
model Notification {
  id          String   @id @default(uuid())
  userId      String
  type        NotificationType
  title       String
  message     String
  data        Json?
  read        Boolean  @default(false)
  sent        Boolean  @default(false)
  sentAt      DateTime?
  createdAt   DateTime @default(now())

  user        User     @relation(fields: [userId], references: [id])
  @@index([userId, read])
}

model Review {
  id             String   @id @default(uuid())
  appointmentId  String   @unique
  clientId       String
  practitionerId String
  rating         Int      // 1-5
  comment        String?
  response       String?
  responseDate   DateTime?
  status         ReviewStatus @default(PENDING)
  helpful        Int      @default(0)
  createdAt      DateTime @default(now())

  appointment    Appointment @relation(fields: [appointmentId], references: [id])
  client         ClientProfile @relation(fields: [clientId], references: [id])
  practitioner   PractitionerProfile @relation(fields: [practitionerId], references: [id])

  @@index([practitionerId, status])
}

model Message {
  id            String   @id @default(uuid())
  conversationId String
  senderId      String
  receiverId    String
  content       String
  attachments   String[]
  read          Boolean  @default(false)
  readAt        DateTime?
  createdAt     DateTime @default(now())

  sender        User     @relation("SentMessages", fields: [senderId], references: [id])
  receiver      User     @relation("ReceivedMessages", fields: [receiverId], references: [id])

  @@index([conversationId])
  @@index([receiverId, read])
}

model NotificationPreference {
  id                 String  @id @default(uuid())
  userId             String  @unique
  emailEnabled       Boolean @default(true)
  smsEnabled         Boolean @default(false)
  pushEnabled        Boolean @default(true)
  appointmentReminders Boolean @default(true)
  promotionalEmails  Boolean @default(true)

  user               User    @relation(fields: [userId], references: [id])
}

enum NotificationType {
  APPOINTMENT_CONFIRMATION
  APPOINTMENT_REMINDER
  APPOINTMENT_CANCELLED
  PAYMENT_SUCCESS
  REVIEW_RECEIVED
  MESSAGE_RECEIVED
  PRACTITIONER_VERIFIED
}

enum ReviewStatus {
  PENDING
  APPROVED
  REJECTED
}
```

---

### Frontend Changes

**New Screens:**
```
frontend/lib/presentation/screens/
├── notifications/
│   ├── notifications_screen.dart
│   └── notification_preferences_screen.dart
├── analytics/
│   ├── practitioner_analytics_screen.dart
│   ├── client_progress_screen.dart
│   └── admin_analytics_screen.dart
├── reviews/
│   ├── write_review_screen.dart
│   ├── reviews_list_screen.dart
│   └── review_detail_screen.dart
├── messaging/
│   ├── conversations_list_screen.dart
│   ├── chat_screen.dart
│   └── new_message_screen.dart
├── admin/
│   ├── admin_dashboard_screen.dart
│   ├── users_management_screen.dart
│   ├── verification_queue_screen.dart
│   └── moderation_screen.dart
└── search/
    ├── advanced_search_screen.dart
    └── search_filters_screen.dart
```

**New Services:**
```
frontend/lib/data/services/
├── notifications_service.dart
├── reviews_service.dart
├── analytics_service.dart
├── messaging_service.dart
├── admin_service.dart
└── firebase_messaging_service.dart
```

**New Models:**
```
frontend/lib/data/models/
├── notification.dart
├── review.dart
├── message.dart
├── conversation.dart
├── analytics_data.dart
└── notification_preference.dart
```

---

## 📊 Success Metrics

### Phase 4A (Notifications & Reviews):
- 📈 Appointment no-show rate < 5% (currently unknown)
- ⭐ 70% of completed appointments reviewed
- 📧 Email open rate > 40%
- 🔔 Push notification opt-in > 60%

### Phase 4B (Analytics):
- 📊 80% of practitioners check analytics weekly
- 📈 Data-driven booking improvements visible
- 🎯 Client retention improvement measurable

### Phase 4C (Search & Discovery):
- 🔍 Search usage increase 50%
- ⚡ Conversion rate from search to booking +30%
- 📱 Average search time reduced by 40%

### Phase 4D (Messaging):
- 💬 30% of client-practitioner pairs use messaging
- ⏱️ Response time < 2 hours average
- 📈 Client satisfaction increase

### Phase 4E (Financial):
- 💰 Invoice generation used by 80% of practitioners
- 📊 Payout clarity improved (survey)
- 🔄 Failed payment recovery rate > 50%

---

## 🚀 Quick Start Priority

**If you want to start Phase 4 immediately, I recommend:**

### Option 1: Notifications First (Highest Impact)
Start with Module 1 to reduce no-shows and improve engagement.

### Option 2: Reviews First (Build Trust)
Start with Module 3 to build social proof and trust.

### Option 3: Analytics First (Data-Driven)
Start with Module 2 to give users insights.

**Which would you like to start with?**

---

## 📝 Next Steps

1. **Choose Priority Module** - Which feature should we build first?
2. **Create Branch** - `claude/sana-mvp-phase-4-[module-name]`
3. **Design Database Schema** - Add new Prisma models
4. **Implement Backend** - Services and controllers
5. **Build Frontend** - Screens and integration
6. **Test & Deploy** - QA and production release

**Ready to start? Which module should we tackle first?** 🚀
