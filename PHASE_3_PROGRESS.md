# Phase 3: Bookings & Payments - IN PROGRESS 🚧

## Overview
Phase 3 implements the complete appointment booking system with Stripe payments, session notes, and client outcomes tracking.

---

## Backend Implementation (NestJS/TypeScript) ✅

### 1. Appointments Module ✅ COMPLETE

**AppointmentsService** (`backend/src/appointments/appointments.service.ts`)

**Core Booking:**
- `createAppointment()` - Book appointment with conflict detection, verification
- `getAppointments()` - List with filters (status, date range, role-based)
- `getAppointmentById()` - Full details including notes and outcomes
- `updateAppointment()` - Reschedule with conflict checking
- `cancelAppointment()` - Cancel with 24-hour notice tracking

**Practitioner Actions:**
- `confirmAppointment()` - Confirm scheduled appointment
- `completeAppointment()` - Mark as complete after session

**Availability:**
- `getAvailableSlots()` - Generate 30-min slots from practitioner availability
- Conflict detection across all bookings
- Past appointment filtering

**Status Management:**
- Valid transitions: SCHEDULED → CONFIRMED → COMPLETED/CANCELLED/NO_SHOW
- Status validation on updates
- Automatic confirmation on payment

**AppointmentsController** - 8 endpoints:
```
POST   /api/appointments                    [CLIENT] Create appointment
GET    /api/appointments                    [AUTH] List appointments
GET    /api/appointments/:id                [AUTH] Get appointment details  
GET    /api/appointments/slots/:practitionerId [PUBLIC] Available slots
PUT    /api/appointments/:id                [AUTH] Update/reschedule
DELETE /api/appointments/:id                [AUTH] Cancel appointment
POST   /api/appointments/:id/confirm        [PRACTITIONER] Confirm
POST   /api/appointments/:id/complete       [PRACTITIONER] Complete
```

---

### 2. Payments Module (Stripe) ✅ COMPLETE

**PaymentsService** (`backend/src/payments/payments.service.ts`)

**Stripe Integration:**
- `createPaymentIntent()` - Creates Stripe payment intent for appointments
- Amount conversion to pence (GBP × 100)
- Payment intent metadata (appointment, client, practitioner details)
- Duplicate prevention (returns existing intent if found)

**Payment Processing:**
- `confirmPayment()` - Confirms payment, updates appointment status
- `getPayment()` - Get payment details with access control
- `getPayments()` - Payment history (client/practitioner views)
- `refundPayment()` - Full refund processing via Stripe

**Webhook Handler:**
- `handleStripeWebhook()` - Processes Stripe events
- Handles: payment_intent.succeeded, payment_intent.payment_failed, charge.refunded
- Automatic status updates
- Logging for all webhook events

**Payment Status Flow:**
- PENDING → COMPLETED (on successful payment)
- PENDING → FAILED (on payment failure)
- COMPLETED → REFUNDED (on cancellation refund)

**Features:**
- Automatic appointment confirmation on successful payment
- Refund only for cancelled appointments
- Payment history tracking
- Stripe API v2024-11-20.acacia

**PaymentsController** (`backend/src/payments/payments.controller.ts`) ✅ COMPLETE:
```
POST   /api/payments/create-intent          [CLIENT] Create payment intent
GET    /api/payments                         [AUTH] List payments
GET    /api/payments/:id                     [AUTH] Get payment details
POST   /api/payments/:id/refund              [PRACTITIONER] Process refund
POST   /api/payments/webhook                 [PUBLIC] Stripe webhook (signature verified)
```

---

### 3. Session Notes Module ✅ COMPLETE

**SessionNotesService** (`backend/src/session-notes/session-notes.service.ts`)

**Note Management:**
- `createSessionNote()` - Create notes after completed appointments
- `getSessionNote()` - Get note with privacy (clients can't see private notes)
- `getPractitionerSessionNotes()` - List all notes for practitioner
- `getClientSessionNotes()` - List notes for client (private notes excluded)
- `updateSessionNote()` - Update note (practitioner only)
- `deleteSessionNote()` - Delete note (practitioner only)

**Privacy Features:**
- **notes**: Visible to both practitioner and client
- **privateNotes**: Only visible to practitioner
- **recommendations**: Treatment recommendations
- **followUpRequired**: Boolean flag
- **followUpDate**: Scheduled follow-up date

**Validation:**
- Only for completed appointments
- Duplicate prevention (one note per appointment)
- Access control (practitioner or client)

**SessionNotesController** (`backend/src/session-notes/session-notes.controller.ts`) ✅ COMPLETE:
```
POST   /api/session-notes                   [PRACTITIONER] Create note
GET    /api/session-notes                   [AUTH] List notes (privacy filtered)
GET    /api/session-notes/:id               [AUTH] Get note details (privacy filtered)
PUT    /api/session-notes/:id               [PRACTITIONER] Update note
DELETE /api/session-notes/:id               [PRACTITIONER] Delete note
```

---

### 4. Outcomes Module ✅ COMPLETE

**OutcomesService** (`backend/src/outcomes/outcomes.service.ts`)

**Outcome Tracking:**
- `createOutcome()` - Record outcome after completed appointments
- `getOutcome()` - Get outcome with access control
- `getPractitionerOutcomes()` - List all outcomes for practitioner
- `getClientOutcomes()` - List outcomes for client
- `updateOutcome()` - Update outcome (practitioner only)
- `deleteOutcome()` - Delete outcome (practitioner only)

**Statistics:**
- `getPractitionerOutcomeStats()` - Calculate statistics:
  - Total outcomes count
  - Average outcome score
  - Score distribution (1-5)

**Outcome Fields:**
- **outcomeScore**: 1-5 scale (validated)
- **improvementNotes**: Detailed improvement notes
- **goalsAchieved**: Array of achieved goals
- **nextSteps**: Recommended next steps

**Features:**
- Outcome score validation (1-5)
- Duplicate prevention (one outcome per appointment)
- Statistical analysis for practitioner performance
- Access control (practitioner or client)

**OutcomesController** (`backend/src/outcomes/outcomes.controller.ts`) ✅ COMPLETE:
```
POST   /api/outcomes                        [PRACTITIONER] Create outcome
GET    /api/outcomes                        [AUTH] List outcomes
GET    /api/outcomes/stats                  [PRACTITIONER] Get statistics
GET    /api/outcomes/:id                    [AUTH] Get outcome details
PUT    /api/outcomes/:id                    [PRACTITIONER] Update outcome
DELETE /api/outcomes/:id                    [PRACTITIONER] Delete outcome
```

---

## Backend Status Summary

**✅ COMPLETED - ALL BACKEND MODULES:**
- Appointments service (10 methods) + controller (8 endpoints)
- Payments service (9 methods + Stripe integration) + controller (5 endpoints)
- Session Notes service (6 methods) + controller (5 endpoints)
- Outcomes service (7 methods) + controller (6 endpoints)

**Total Backend:**
- 4 modules: 100% complete ✅
- 32 service methods
- 24 API endpoints live
- Stripe webhook integration with signature verification
- Role-based access control (CLIENT, PRACTITIONER)
- Privacy filtering for session notes

---

## Frontend Implementation (Flutter)

### ✅ Data Layer Complete (Models & Services)

**Models Created** (`frontend/lib/data/models/`):
- `appointment.dart`: Appointment, AppointmentStatus enum, AvailableTimeSlot
- `payment.dart`: Payment, PaymentStatus enum, PaymentIntentResponse
- `session_note.dart`: SessionNote, CreateSessionNoteRequest
- `outcome.dart`: Outcome, OutcomeStatistics, CreateOutcomeRequest

All models use Freezed for immutability and JSON serialization.

**Services Created** (`frontend/lib/data/services/`):
- `appointments_service.dart`: 8 methods (create, list, get, update, cancel, confirm, complete, getSlots)
- `payments_service.dart`: 4 methods (createIntent, list, get, refund)
- `session_notes_service.dart`: 5 methods (create, list, get, update, delete)
- `outcomes_service.dart`: 6 methods (create, list, get, getStats, update, delete)

All services use Riverpod providers and Dio for API communication.

**Dependencies Added:**
- flutter_stripe: ^10.1.1 (for payment processing)
- dioProvider added to api_service.dart for service injection

**Status:** Data layer 100% complete ✅

---

### 🚧 UI Screens (TODO)

**1. Appointment Booking Screen**
- Practitioner profile display
- Session type selection
- Date picker with available slots
- Time slot selection (30-min intervals)
- Booking confirmation
- Notes field

**2. Appointments Calendar View**
- Month/week/day views
- Upcoming appointments list
- Past appointments list
- Filter by status (scheduled, confirmed, completed)
- Cancel appointment flow
- Reschedule appointment

**3. Payment Flow Screen**
- Stripe payment sheet integration
- Payment amount display
- Payment confirmation
- Payment history view
- Receipt view

**4. Session Notes Screen (Practitioner)**
- Create notes after appointment
- Rich text editor
- Private notes section
- Recommendations field
- Follow-up scheduler
- Notes history view

**5. Client Outcomes Screen (Practitioner)**
- Outcome score selector (1-5)
- Improvement notes
- Goals achieved checklist
- Next steps field
- Outcomes history
- Statistics dashboard

**6. My Appointments Screen (Client)**
- Upcoming appointments card list
- Appointment details view
- View session notes
- View outcomes
- Cancel/reschedule options

---

## Environment Variables

Add to `backend/.env`:

```bash
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Existing vars
DATABASE_URL=...
JWT_SECRET=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

---

## API Integration Summary

**Appointments Flow:**
1. Client searches practitioners → GET /practitioners/search
2. Selects practitioner → GET /practitioners/:id/public
3. Views available slots → GET /appointments/slots/:practitionerId?date=2025-11-05
4. Books appointment → POST /appointments
5. Makes payment → POST /payments/create-intent
6. Payment confirmed → Webhook updates appointment status
7. Practitioner confirms → POST /appointments/:id/confirm
8. Session completed → POST /appointments/:id/complete
9. Practitioner adds notes → POST /session-notes
10. Practitioner records outcome → POST /outcomes

**Payment Flow:**
1. Create payment intent → Returns client_secret
2. Flutter app uses Stripe SDK with client_secret
3. Stripe processes payment
4. Webhook confirms → Appointment status → CONFIRMED
5. If cancelled → POST /payments/:id/refund

**Session Notes Flow:**
1. Appointment completed → Status: COMPLETED
2. Practitioner creates notes → POST /session-notes
3. Client views notes → GET /session-notes (private notes excluded)
4. Practitioner updates → PUT /session-notes/:id

**Outcomes Flow:**
1. Session completed → Status: COMPLETED
2. Practitioner records outcome → POST /outcomes (score 1-5)
3. Client views outcome → GET /outcomes
4. Stats calculated → GET /outcomes/stats
5. SANA Index updated → Based on average outcome scores

---

## Data Models

**Appointment:**
```typescript
{
  id: string
  clientId: string
  practitionerId: string
  sessionTypeId: string
  appointmentDate: Date
  status: 'SCHEDULED' | 'CONFIRMED' | 'COMPLETED' | 'CANCELLED' | 'NO_SHOW'
  notes?: string
  payment?: Payment
  sessionNotes?: SessionNote
  outcome?: ClientOutcome
}
```

**Payment:**
```typescript
{
  id: string
  appointmentId: string
  amount: number  // GBP
  currency: 'GBP'
  status: 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED'
  stripePaymentIntentId: string
  stripeClientSecret?: string
  paidAt?: Date
  refundedAt?: Date
}
```

**SessionNote:**
```typescript
{
  id: string
  appointmentId: string
  notes: string  // Visible to client
  privateNotes?: string  // Practitioner only
  recommendations?: string
  followUpRequired: boolean
  followUpDate?: Date
}
```

**ClientOutcome:**
```typescript
{
  id: string
  appointmentId: string
  outcomeScore: number  // 1-5
  improvementNotes?: string
  goalsAchieved: string[]
  nextSteps?: string
}
```

---

## Next Steps

**Backend: ✅ COMPLETE**

**Now (Flutter UI):**
1. Create appointment booking flow
2. Integrate Stripe Flutter SDK
3. Build appointment calendar views
4. Create session notes UI for practitioners
5. Build outcomes tracking UI
6. Add appointment management for clients

**Testing:**
1. End-to-end booking flow
2. Stripe payment integration (test mode)
3. Webhook handling
4. Session notes privacy
5. Outcomes statistics calculation

---

## Commits

**Phase 3 Backend:**
- `e20d933` - Appointments and Stripe Payments (Part 1)
- `be55cd1` - Session Notes and Outcomes modules
- `dc787b1` - Add Phase 3 progress documentation
- `f88ca8e` - Complete Phase 3 Backend: Implement remaining controllers
- `eff2b45` - Update Phase 3 progress: Backend 100% complete
- `a3fadca` - Add backend package-lock.json

**Phase 3 Frontend (Flutter):**
- `e19281b` - Add Phase 3 Flutter data layer: models and services

**Status:**
- Backend: 100% complete ✅
- Frontend Data Layer: 100% complete ✅
- Frontend UI: 0% complete
- Overall Phase 3: 60% complete

---

**Phase 3 Status: Backend Complete ✅ | Frontend TODO 🚧**
**Branch:** `claude/sana-mvp-phase-1-011CUpvAdYVuWqczEEF2Prqd`
**Last Updated:** November 5, 2025 - Backend 100% Complete
