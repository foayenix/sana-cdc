# SANA Platform - Performance Optimization Guide

## Overview

This document outlines the performance optimizations implemented in Phase 4 Module 10 and provides best practices for maintaining optimal performance.

---

## Backend Optimizations

### 1. Database Indexing ✅

**Status**: 63+ indexes implemented in Prisma schema

**Key Indexes**:
- User lookup: `email`, `googleId`
- Appointments: `clientId`, `practitionerId`, `scheduledAt`, `status`
- Payments: `clientId`, `practitionerId`, `status`, `createdAt`
- Notifications: `userId + read`, `userId + createdAt`, `type`
- Messages: `conversationId`, `receiverId + read`
- Reviews: `practitionerId + isPublished`, `rating`, `createdAt`

**Best Practices**:
```prisma
// ✅ Good: Index on frequently queried fields
@@index([userId, status])
@@index([createdAt])

// ❌ Avoid: Too many indexes (slows writes)
// Only index fields used in WHERE, JOIN, ORDER BY
```

---

### 2. API Rate Limiting ✅

**Current Configuration**:
```typescript
ThrottlerModule.forRoot([{
  ttl: 60000,  // 60 seconds
  limit: 10,   // 10 requests per TTL
}])
```

**Environment Variables**:
```bash
RATE_LIMIT_TTL=60      # Seconds
RATE_LIMIT_MAX=10      # Max requests
```

**Customization** per route:
```typescript
@Throttle({ default: { limit: 3, ttl: 60000 } })
@Post('send-email')
async sendEmail() { ... }
```

---

### 3. Response Caching

**Implementation**: `backend/src/common/interceptors/cache.interceptor.ts`

**Usage**:
```typescript
// Option 1: Decorator (recommended)
import { Cacheable } from './common/decorators/cacheable.decorator';

@Cacheable(60)  // Cache for 60 seconds
@Get('practitioners')
async findAll() { ... }

// Option 2: Manual interceptor
@UseInterceptors(new CacheInterceptor(300))  // 5 minutes
@Get('practitioners/:id')
async findOne(@Param('id') id: string) { ... }
```

**Cache Strategies**:
- **Short TTL (30-60s)**: User-specific data, notifications
- **Medium TTL (5-15min)**: Practitioner lists, session types
- **Long TTL (30-60min)**: Static content, recommendations

**Cache Invalidation**:
```typescript
// Clear all cache
cacheInterceptor.clearAll();

// Clear by pattern
cacheInterceptor.clearPattern(/^.*:\/practitioners.*/);
```

**Production**: Replace with Redis for distributed caching:
```typescript
// TODO: Install @nestjs/cache-manager and cache-manager-redis-store
import { CacheModule } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-redis-store';

CacheModule.register({
  store: redisStore,
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
  ttl: 60,
})
```

---

### 4. Performance Monitoring

**Implementation**: `backend/src/common/interceptors/performance.interceptor.ts`

**Features**:
- Request timing (logs slow requests > 1000ms)
- Error tracking with context
- Ready for integration with DataDog, New Relic

**Usage**:
```typescript
// Apply globally in main.ts
app.useGlobalInterceptors(new PerformanceInterceptor());

// Or per controller
@UseInterceptors(PerformanceInterceptor)
@Controller('appointments')
export class AppointmentsController { ... }
```

**Integration with Monitoring Services**:
```typescript
// In performance.interceptor.ts, update:
private sendToMonitoringService(metrics: any): void {
  // DataDog example:
  datadog.increment('http.request', 1, [
    `status:${metrics.statusCode}`,
    `method:${metrics.method}`
  ]);

  // New Relic example:
  newrelic.recordMetric('Custom/RequestTime', metrics.elapsedTime);
}
```

---

### 5. Error Tracking

**Implementation**: `backend/src/common/utils/error-tracker.util.ts`

**Setup** (in main.ts):
```typescript
import { ErrorTracker } from './common/utils/error-tracker.util';

ErrorTracker.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  release: process.env.APP_VERSION,
});
```

**Usage**:
```typescript
try {
  await processPayment(paymentData);
} catch (error) {
  ErrorTracker.captureException(error, {
    userId: user.id,
    action: 'payment-processing',
    amount: paymentData.amount,
  });
  throw error;
}

// Non-exception tracking
ErrorTracker.captureMessage('Unusual activity detected', 'warning', {
  userId: user.id,
  ipAddress: req.ip,
});
```

**Sentry Integration** (when ready):
```bash
npm install @sentry/node @sentry/integrations
```

```typescript
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: config.dsn,
  environment: config.environment,
  tracesSampleRate: 0.1,  // 10% of transactions
  integrations: [
    new Sentry.Integrations.Http({ tracing: true }),
    new Sentry.Integrations.Express({ app }),
  ],
});
```

---

### 6. Image Optimization

**Implementation**: `backend/src/common/utils/image-optimizer.util.ts`

**Dependencies**:
```bash
npm install sharp  # High-performance image processing
```

**Usage**:
```typescript
import { ImageOptimizer } from './common/utils/image-optimizer.util';

// Optimize uploaded image
const optimizedBuffer = await ImageOptimizer.optimize(inputBuffer, {
  maxWidth: 1200,
  quality: 85,
  format: 'webp',  // Modern format, better compression
});

// Create thumbnail
const thumbnail = await ImageOptimizer.createThumbnail(inputBuffer, 200);

// Create responsive sizes
const sizes = await ImageOptimizer.createResponsiveSizes(inputBuffer, [
  320, 640, 1024, 1920
]);

// Validate image before processing
const validation = await ImageOptimizer.validateImage(inputBuffer);
if (!validation.valid) {
  throw new Error(validation.error);
}
```

**S3 Upload with Optimization**:
```typescript
async uploadProfilePhoto(file: Express.Multer.File): Promise<string> {
  // Validate
  const validation = await ImageOptimizer.validateImage(file.buffer);
  if (!validation.valid) throw new BadRequestException(validation.error);

  // Optimize
  const optimized = await ImageOptimizer.optimize(file.buffer, {
    maxWidth: 1200,
    quality: 85,
    format: 'webp',
  });

  // Create thumbnail
  const thumbnail = await ImageOptimizer.createThumbnail(file.buffer, 200);

  // Upload both
  const mainUrl = await this.s3Service.upload(optimized, 'profiles');
  const thumbUrl = await this.s3Service.upload(thumbnail, 'profiles/thumbs');

  return mainUrl;
}
```

---

## Frontend Optimizations

### 1. Error Boundaries ✅

**Implementation**: `frontend/lib/core/error/error_boundary.dart`

**Usage**:
```dart
// Wrap entire app
ErrorBoundary(
  onError: (error, stackTrace) {
    // Send to error tracking service
    // Sentry.captureException(error, stackTrace: stackTrace);
  },
  child: MyApp(),
)

// Wrap specific widgets
ErrorBoundary(
  child: ComplexWidget(),
  errorBuilder: (error) => CustomErrorWidget(error),
)
```

**Global Error Handling** (in main.dart):
```dart
void main() {
  GlobalErrorHandler.init(
    onError: (error, stackTrace) {
      // Send to analytics/error tracking
      print('Error: $error');
    },
  );

  runApp(
    ErrorBoundary(
      child: MyApp(),
    ),
  );
}
```

---

### 2. Code Splitting & Lazy Loading

**Deferred Loading** (Flutter Web):
```dart
// Import with deferred
import 'package:sana_app/screens/heavy_screen.dart' deferred as heavy;

// Load when needed
ElevatedButton(
  onPressed: () async {
    await heavy.loadLibrary();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => heavy.HeavyScreen()),
    );
  },
  child: Text('Open Heavy Screen'),
)
```

**Lazy Widgets**:
```dart
// Don't build until needed
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    // Only builds visible items
    return ItemWidget(items[index]);
  },
)
```

---

### 3. Image Loading Optimization

**Use cached_network_image**:
```bash
flutter pub add cached_network_image
```

```dart
CachedNetworkImage(
  imageUrl: profilePhotoUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fadeInDuration: Duration(milliseconds: 300),
  memCacheWidth: 200,  // Resize in memory
  maxWidthDiskCache: 400,  // Resize on disk
)
```

---

### 4. State Management Optimization

**Riverpod Best Practices**:
```dart
// ✅ Good: Use family for parameterized providers
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  return fetchUser(userId);
});

// ✅ Good: Use autoDispose for temporary data
final searchResultsProvider = StateProvider.autoDispose<List<Result>>((ref) => []);

// ❌ Avoid: Rebuilding entire tree
// Use Consumer/ConsumerWidget instead of wrapping entire screen
```

---

## Database Query Optimization

### Query Best Practices

**Include only needed fields**:
```typescript
// ✅ Good: Select specific fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true,
  },
});

// ❌ Avoid: Fetching all relations
const users = await prisma.user.findMany({
  include: {
    clientProfile: { include: { dailyCheckins: true, journals: true } },
    practitionerProfile: { include: { appointments: true, reviews: true } },
  },
});
```

**Use pagination**:
```typescript
// ✅ Good: Limit + offset
const appointments = await prisma.appointment.findMany({
  take: 20,
  skip: page * 20,
  orderBy: { scheduledAt: 'desc' },
});

// ❌ Avoid: Loading all records
const allAppointments = await prisma.appointment.findMany();
```

**Batch queries with dataloader pattern**:
```typescript
// Instead of N+1 queries
for (const appointment of appointments) {
  const client = await prisma.user.findUnique({ where: { id: appointment.clientId } });
}

// ✅ Good: Single query
const clientIds = appointments.map(a => a.clientId);
const clients = await prisma.user.findMany({
  where: { id: { in: clientIds } },
});
```

---

## Monitoring & Observability

### Key Metrics to Track

**Backend**:
- Response times (p50, p95, p99)
- Error rates by endpoint
- Database query times
- Cache hit/miss ratios
- Memory usage
- CPU usage

**Frontend**:
- Screen load times
- API call latency
- Error rates
- Crash rates
- Network failures

### Recommended Tools

**Error Tracking**:
- Sentry (errors + performance)
- Rollbar
- Bugsnag

**APM (Application Performance Monitoring)**:
- New Relic
- DataDog
- Dynatrace

**Infrastructure**:
- CloudWatch (AWS)
- Google Cloud Monitoring
- Azure Monitor

---

## Performance Checklist

### Before Deployment

**Backend**:
- [ ] All database queries have appropriate indexes
- [ ] Expensive operations are cached
- [ ] Rate limiting is configured
- [ ] Error tracking is set up
- [ ] Performance monitoring is enabled
- [ ] Images are optimized before storage
- [ ] API responses are gzipped

**Frontend**:
- [ ] Error boundaries are in place
- [ ] Images use lazy loading
- [ ] Large lists use pagination
- [ ] Heavy computations are debounced
- [ ] Network requests have retry logic
- [ ] Error states are handled gracefully

### Ongoing Optimization

**Weekly**:
- Review slow query logs
- Check error rates
- Monitor cache hit ratios

**Monthly**:
- Analyze performance trends
- Review and optimize top 10 slowest endpoints
- Update dependencies for security and performance

**Quarterly**:
- Database query optimization review
- Load testing
- Capacity planning

---

## Common Performance Anti-Patterns

### ❌ Avoid These

**Backend**:
```typescript
// ❌ N+1 Query Problem
for (const user of users) {
  const appointments = await prisma.appointment.findMany({
    where: { clientId: user.id },
  });
}

// ❌ Missing pagination
const allUsers = await prisma.user.findMany(); // Could be millions

// ❌ Not using indexes
// Missing: @@index([email, status]) in schema

// ❌ Synchronous heavy operations
const processedImage = processImageSync(largeFile); // Blocks event loop
```

**Frontend**:
```dart
// ❌ Building entire list at once
Column(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// ❌ Not using const constructors
Container(
  child: Text('Static text'),  // Rebuilt every time
)

// ❌ Heavy computations in build method
Widget build(BuildContext context) {
  final expensiveResult = heavyComputation();  // Runs on every rebuild!
  return Text(expensiveResult);
}
```

---

## Next Steps

1. **Set up Sentry**: Add SENTRY_DSN to environment variables
2. **Configure Redis**: For distributed caching in production
3. **Enable CDN**: For static assets and images
4. **Set up monitoring dashboards**: In DataDog/New Relic
5. **Implement CI/CD performance tests**: Automated lighthouse scores

---

## Resources

- [Prisma Query Optimization](https://www.prisma.io/docs/guides/performance-and-optimization)
- [NestJS Performance](https://docs.nestjs.com/techniques/performance)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Sharp Image Processing](https://sharp.pixelplumbing.com/)
- [Sentry Documentation](https://docs.sentry.io/)

---

**Last Updated**: Phase 4 Module 10 - November 2024
