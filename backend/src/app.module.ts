import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { QuestionnaireModule } from './questionnaire/questionnaire.module';
import { CheckinModule } from './checkin/checkin.module';
import { RecommendationsModule } from './recommendations/recommendations.module';
import { PractitionersModule } from './practitioners/practitioners.module';
import { SessionTypesModule } from './session-types/session-types.module';
import { AppointmentsModule } from './appointments/appointments.module';
import { SessionNotesModule } from './session-notes/session-notes.module';
import { OutcomesModule } from './outcomes/outcomes.module';
import { JournalModule } from './journal/journal.module';
import { PaymentsModule } from './payments/payments.module';
import { SanaIndexModule } from './sana-index/sana-index.module';
import { UploadsModule } from './uploads/uploads.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Rate limiting (security)
    ThrottlerModule.forRoot([
      {
        ttl: parseInt(process.env.RATE_LIMIT_TTL || '60', 10) * 1000,
        limit: parseInt(process.env.RATE_LIMIT_MAX || '10', 10),
      },
    ]),

    // Cron jobs
    ScheduleModule.forRoot(),

    // Core modules
    PrismaModule,
    AuthModule,
    UsersModule,
    QuestionnaireModule,
    CheckinModule,
    RecommendationsModule,
    PractitionersModule,
    SessionTypesModule,
    AppointmentsModule,
    SessionNotesModule,
    OutcomesModule,
    JournalModule,
    PaymentsModule,
    SanaIndexModule,
    UploadsModule,
    NotificationsModule,
    AnalyticsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
