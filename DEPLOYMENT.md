# SANA CDC Deployment Guide

This document provides comprehensive instructions for deploying SANA CDC to production.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Configuration](#environment-configuration)
3. [Database Setup](#database-setup)
4. [Backend Deployment](#backend-deployment)
5. [Frontend Deployment](#frontend-deployment)
6. [Monitoring & Logging](#monitoring--logging)
7. [Backup & Recovery](#backup--recovery)
8. [Security Checklist](#security-checklist)
9. [Post-Deployment](#post-deployment)

---

## Prerequisites

### Required Services
- **Database**: PostgreSQL 14+ (Neon, AWS RDS, or self-hosted)
- **File Storage**: AWS S3 or Cloudflare R2
- **Email Service**: SendGrid, AWS SES, or similar
- **Payment Processing**: Stripe account with Connect enabled
- **Error Tracking**: Sentry account (optional but recommended)
- **Hosting**: Railway, Render, AWS, or similar for backend
- **CDN**: Cloudflare or AWS CloudFront for frontend

### Local Requirements
- Node.js 18+ and npm/yarn
- Flutter SDK 3.x
- PostgreSQL client (for migrations)
- Git

---

## Environment Configuration

### Backend Environment Variables (.env)

```env
# App Configuration
NODE_ENV=production
PORT=3000
FRONTEND_URL=https://app.sana-cdc.com

# Database
DATABASE_URL=postgresql://user:password@host:5432/sana_cdc?ssl=true

# JWT Authentication
JWT_SECRET=<generate-strong-secret-256-bits>
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=<generate-different-strong-secret>
JWT_REFRESH_EXPIRES_IN=7d
BCRYPT_ROUNDS=12

# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_live_...

# File Storage (S3 or R2)
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=eu-west-2
AWS_S3_BUCKET=sana-uploads
AWS_ENDPOINT=https://... # Optional, for Cloudflare R2

# Email
EMAIL_FROM=noreply@sana-cdc.com
EMAIL_PROVIDER=sendgrid # or aws-ses
SENDGRID_API_KEY=...
# OR for AWS SES:
# AWS_SES_REGION=eu-west-1

# Error Tracking
SENTRY_DSN=https://...@sentry.io/...
SENTRY_TRACES_SAMPLE_RATE=0.1

# Rate Limiting
RATE_LIMIT_TTL=60
RATE_LIMIT_MAX=10

# Optional: Redis for caching
REDIS_URL=redis://...
```

### Frontend Environment Variables

```env
# API
API_BASE_URL=https://api.sana-cdc.com

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_live_...

# Sentry (optional)
SENTRY_DSN=https://...@sentry.io/...
```

---

## Database Setup

### 1. Create Production Database

#### Using Neon (Recommended)
```bash
# Create database at neon.tech
# Copy connection string to DATABASE_URL
```

#### Using AWS RDS
```bash
aws rds create-db-instance \
  --db-instance-identifier sana-cdc-prod \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password <strong-password> \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxx
```

### 2. Run Migrations

```bash
cd backend
npx prisma migrate deploy
npx prisma generate
```

### 3. Seed Initial Data (if needed)

```bash
npm run seed:prod
```

### 4. Database Indexes

Verify all indexes are created:
```sql
SELECT tablename, indexname FROM pg_indexes WHERE schemaname = 'public';
```

---

## Backend Deployment

### Option 1: Railway (Recommended)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Create project
railway init

# Link to project
railway link

# Set environment variables
railway variables set NODE_ENV=production
railway variables set DATABASE_URL=<your-database-url>
# ... set all other variables

# Deploy
railway up
```

### Option 2: Render

1. Create new Web Service
2. Connect GitHub repository
3. Set build command: `cd backend && npm install && npx prisma generate && npm run build`
4. Set start command: `cd backend && npm run start:prod`
5. Add environment variables
6. Deploy

### Option 3: AWS ECS/Fargate

```bash
# Build Docker image
cd backend
docker build -t sana-backend:latest .

# Push to ECR
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-west-2.amazonaws.com
docker tag sana-backend:latest <account-id>.dkr.ecr.eu-west-2.amazonaws.com/sana-backend:latest
docker push <account-id>.dkr.ecr.eu-west-2.amazonaws.com/sana-backend:latest

# Deploy to ECS (use AWS Console or terraform)
```

### Dockerfile for Backend

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma
EXPOSE 3000
CMD ["node", "dist/main"]
```

---

## Frontend Deployment

### Build Flutter Web App

```bash
cd frontend
flutter build web --release --web-renderer html
```

### Option 1: Cloudflare Pages

```bash
# Install Wrangler CLI
npm install -g wrangler

# Deploy
wrangler pages publish build/web --project-name sana-cdc
```

### Option 2: AWS S3 + CloudFront

```bash
# Build
flutter build web --release

# Upload to S3
aws s3 sync build/web s3://sana-cdc-frontend --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id E123456 --paths "/*"
```

### Option 3: Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=build/web
```

---

## Monitoring & Logging

### 1. Set Up Sentry

**Backend:**
- Already configured in `main.ts`
- Add `SENTRY_DSN` to environment variables
- Verify errors are being captured

**Frontend (Flutter):**
```dart
// Add to main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.tracesSampleRate = 0.1;
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

### 2. Set Up Uptime Monitoring

#### Using UptimeRobot (Free)
1. Go to [uptimerobot.com](https://uptimerobot.com)
2. Create monitors for:
   - `https://api.sana-cdc.com/api` (HTTP monitor)
   - `https://app.sana-cdc.com` (HTTP monitor)
3. Set alert email/SMS

#### Using AWS CloudWatch
```bash
# Create alarm for API health check
aws cloudwatch put-metric-alarm \
  --alarm-name sana-api-health \
  --alarm-description "SANA API Health Check" \
  --metric-name HealthCheckStatus \
  --namespace AWS/Route53 \
  --statistic Minimum \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 1 \
  --comparison-operator LessThanThreshold
```

### 3. Application Performance Monitoring

**Recommended Tools:**
- **Sentry Performance**: Already integrated
- **New Relic**: Add agent to backend
- **Datadog**: Add agent to backend

---

## Backup & Recovery

### 1. Automated Database Backups

#### Neon (Automatic)
- Backups every 24 hours
- 7-day retention
- Point-in-time recovery available

#### AWS RDS
```bash
# Enable automated backups
aws rds modify-db-instance \
  --db-instance-identifier sana-cdc-prod \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00"
```

#### Manual Backup Script
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump $DATABASE_URL | gzip > "backup_${DATE}.sql.gz"
aws s3 cp "backup_${DATE}.sql.gz" s3://sana-backups/database/
```

Add to cron:
```bash
0 3 * * * /path/to/backup.sh
```

### 2. File Storage Backups

```bash
# Sync S3 bucket to backup location
aws s3 sync s3://sana-uploads s3://sana-backups/uploads --storage-class GLACIER
```

### 3. Recovery Procedures

**Database Restore:**
```bash
# Download latest backup
aws s3 cp s3://sana-backups/database/backup_latest.sql.gz .

# Restore
gunzip backup_latest.sql.gz
psql $DATABASE_URL < backup_latest.sql
```

---

## Security Checklist

### Pre-Deployment
- [ ] All environment variables are set correctly
- [ ] No hardcoded secrets in code
- [ ] Database uses SSL/TLS connections
- [ ] HTTPS enforced on all routes (handled in `main.ts`)
- [ ] Rate limiting enabled (configured in `app.module.ts`)
- [ ] CORS configured for production domain only
- [ ] Stripe webhook signatures verified
- [ ] File upload validation enabled (10MB limit, JPG/PNG/PDF only)
- [ ] JWT secrets are strong (256+ bits)
- [ ] bcrypt rounds set to 12+

### Post-Deployment
- [ ] Run security scan (npm audit, Snyk)
- [ ] Test Stripe Connect flow end-to-end
- [ ] Verify GDPR data export works
- [ ] Test account deletion flow
- [ ] Verify email notifications work
- [ ] Check Sentry error tracking
- [ ] Test payment webhooks
- [ ] Verify HTTPS redirect works
- [ ] Check rate limiting is active
- [ ] Review CloudWatch/monitoring dashboards

---

## Post-Deployment

### 1. Health Checks

```bash
# API health
curl https://api.sana-cdc.com/api

# Database connection
curl https://api.sana-cdc.com/api/health

# Stripe webhook endpoint
curl https://api.sana-cdc.com/api/payments/webhook
```

### 2. Performance Testing

```bash
# Load testing with Artillery
npm install -g artillery
artillery quick --count 100 --num 10 https://api.sana-cdc.com/api
```

### 3. Monitoring Dashboards

Set up dashboards for:
- Request rate and latency
- Error rates (4xx, 5xx)
- Database connections and query performance
- Payment success/failure rates
- User registrations and logins
- Appointment bookings
- Stripe Connect onboarding completion rate

### 4. Alerting

Configure alerts for:
- API response time > 2s (P2)
- Error rate > 5% (P1)
- Database CPU > 80% (P2)
- Payment failure rate > 10% (P1)
- Disk usage > 85% (P2)

---

## Common Issues & Troubleshooting

### Database Connection Errors
```bash
# Check SSL mode
psql "$DATABASE_URL?sslmode=require"

# Test from application server
telnet database-host 5432
```

### Stripe Webhook Failures
```bash
# Check webhook signature
curl -X POST https://api.sana-cdc.com/api/payments/webhook \
  -H "stripe-signature: test" \
  -d '{"type":"payment_intent.succeeded"}'
```

### High Memory Usage
```bash
# Restart application
railway restart
# or
pm2 restart sana-backend
```

---

## Rollback Procedures

### Backend Rollback
```bash
# Railway
railway rollback

# Render
# Use Render dashboard to rollback to previous deploy

# ECS
aws ecs update-service --cluster sana-cluster --service sana-backend --task-definition sana-backend:previous-version
```

### Database Rollback
```bash
# Use backup restore procedure above
# Or use Prisma migrations
cd backend
npx prisma migrate resolve --rolled-back 20240101000000_migration_name
```

---

## Support & Maintenance

### Regular Maintenance Tasks
- **Daily**: Review error logs in Sentry
- **Weekly**: Check database performance metrics
- **Monthly**: Review and rotate API keys
- **Quarterly**: Security audit and dependency updates

### Emergency Contacts
- DevOps Lead: [email]
- Database Admin: [email]
- Security Lead: [email]

---

**Last Updated**: {{ date }}
**Version**: 1.0.0
