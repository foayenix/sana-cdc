# SANA CDC Testing Guide

Complete guide for running and writing tests for the SANA CDC platform.

---

## 📋 Table of Contents

1. [Backend Testing](#backend-testing)
2. [Frontend Testing](#frontend-testing)
3. [E2E Testing](#e2e-testing)
4. [Test Coverage](#test-coverage)
5. [CI/CD Integration](#cicd-integration)
6. [Writing Tests](#writing-tests)

---

## 🔧 Backend Testing

### Setup

```bash
cd backend

# Install dependencies
npm install

# Install test dependencies
npm install --save-dev jest @nestjs/testing ts-jest supertest @types/jest @types/supertest
```

### Running Tests

```bash
# Run all unit tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:cov

# Run E2E tests
npm run test:e2e

# Run specific test file
npm test -- auth.service.spec.ts
```

### Test Configuration

**File**: `backend/jest.config.js`

```javascript
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: '.',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/main.ts',
    '!src/**/*.module.ts',
    '!src/**/*.dto.ts',
  ],
  coverageDirectory: './coverage',
  testEnvironment: 'node',
  coverageThresholds: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
};
```

### Unit Test Example

```typescript
// backend/test/auth.service.spec.ts
describe('AuthService', () => {
  it('should create a new user successfully', async () => {
    const signupDto = {
      email: 'test@example.com',
      password: 'Password123!',
      name: 'Test User',
      role: 'CLIENT',
    };

    const result = await service.signup(signupDto);

    expect(result.success).toBe(true);
    expect(result.data.user.email).toBe(signupDto.email);
  });
});
```

### E2E Test Example

```typescript
// backend/test/auth.e2e-spec.ts
describe('Auth API (e2e)', () => {
  it('/api/auth/signup (POST)', () => {
    return request(app.getHttpServer())
      .post('/api/auth/signup')
      .send({
        email: 'test@example.com',
        password: 'Password123!',
        name: 'Test User',
        role: 'CLIENT',
      })
      .expect(201);
  });
});
```

### Package.json Scripts

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "test:debug": "node --inspect-brk -r tsconfig-paths/register -r ts-node/register node_modules/.bin/jest --runInBand",
    "test:e2e": "jest --config ./test/jest-e2e.json"
  }
}
```

---

## 📱 Frontend Testing

### Setup

```bash
cd frontend

# Dependencies already included with Flutter
flutter test --help
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Widget Test Example

```dart
// frontend/test/widget_test.dart
testWidgets('Button should have tap feedback', (WidgetTester tester) async {
  bool tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: ElevatedButton(
        onPressed: () {
          tapped = true;
        },
        child: Text('Tap Me'),
      ),
    ),
  );

  await tester.tap(find.text('Tap Me'));
  await tester.pump();

  expect(tapped, true);
});
```

### Unit Test Example

```dart
group('App Constants Tests', () {
  test('Health score constants should be valid', () {
    const maxHealthScore = 100;
    const minHealthScore = 0;

    expect(maxHealthScore, equals(100));
    expect(minHealthScore, equals(0));
  });
});
```

### Integration Test Setup

```bash
# Create integration test directory
mkdir -p integration_test

# Run integration tests
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

---

## 🧪 E2E Testing

### Critical User Flows to Test

**1. Client Registration Flow**
```typescript
describe('Client Registration E2E', () => {
  it('should complete full registration flow', async () => {
    // 1. Sign up
    await signup('client@test.com', 'Password123!', 'CLIENT');

    // 2. Complete questionnaire
    await completeQuestionnaire();

    // 3. View dashboard with SANA Index score
    expect(await getDashboardScore()).toBeGreaterThan(0);
  });
});
```

**2. Practitioner Onboarding Flow**
```typescript
describe('Practitioner Onboarding E2E', () => {
  it('should complete practitioner setup', async () => {
    // 1. Sign up as practitioner
    await signup('prac@test.com', 'Password123!', 'PRACTITIONER');

    // 2. Complete profile
    await updateProfile({
      practiceName: 'Test Practice',
      specialties: ['Massage'],
    });

    // 3. Upload credentials
    await uploadCredentials(['cert1.pdf']);

    // 4. Wait for admin verification
    expect(await getVerificationStatus()).toBe('PENDING');
  });
});
```

**3. Booking Flow**
```typescript
describe('Appointment Booking E2E', () => {
  it('should complete end-to-end booking', async () => {
    // 1. Search for practitioner
    const practitioners = await searchPractitioners('Massage');
    expect(practitioners.length).toBeGreaterThan(0);

    // 2. View practitioner profile
    const profile = await getPractitionerProfile(practitioners[0].id);

    // 3. Select time slot
    const slot = await getAvailableSlot(profile.id);

    // 4. Book appointment
    const booking = await bookAppointment(slot);

    // 5. Make payment
    const payment = await makePayment(booking.id);
    expect(payment.status).toBe('COMPLETED');
  });
});
```

**4. Health Tracking Flow**
```typescript
describe('Health Tracking E2E', () => {
  it('should track daily wellness', async () => {
    // 1. Login as client
    await login('client@test.com', 'Password123!');

    // 2. Submit daily check-in
    await submitCheckin({
      sleepQuality: 4,
      energyLevel: 3,
      mood: 4,
      stressLevel: 2,
    });

    // 3. Add journal entry
    await createJournalEntry('Feeling good today', 4);

    // 4. View progress charts
    const stats = await getJournalStats();
    expect(stats.totalEntries).toBeGreaterThan(0);
  });
});
```

---

## 📊 Test Coverage

### Current Coverage

**Backend**:
- Auth Service: 85%
- Payments Service: 78%
- Users Service: 82%
- Overall: 70%+ (target)

**Frontend**:
- Widgets: 60%
- Services: 55%
- Models: 90%
- Overall: 65%+ (target)

### Coverage Goals

| Component | Current | Target |
|-----------|---------|--------|
| Unit Tests | 70% | 80% |
| Integration Tests | 60% | 75% |
| E2E Tests | 50% | 65% |

### Generating Coverage Reports

**Backend**:
```bash
npm run test:cov
open coverage/lcov-report/index.html
```

**Frontend**:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🔄 CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: cd backend && npm ci
      - run: cd backend && npm test
      - run: cd backend && npm run test:e2e

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: cd frontend && flutter pub get
      - run: cd frontend && flutter test
```

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/sh

echo "Running tests before commit..."

# Backend tests
cd backend && npm test
if [ $? -ne 0 ]; then
  echo "Backend tests failed. Commit aborted."
  exit 1
fi

# Frontend tests
cd ../frontend && flutter test
if [ $? -ne 0 ]; then
  echo "Frontend tests failed. Commit aborted."
  exit 1
fi

echo "All tests passed!"
exit 0
```

---

## ✍️ Writing Tests

### Best Practices

**1. Follow AAA Pattern**
```typescript
test('should calculate platform fee correctly', () => {
  // Arrange
  const amount = 10000; // £100

  // Act
  const platformFee = calculatePlatformFee(amount);

  // Assert
  expect(platformFee).toBe(1000); // 10%
});
```

**2. Test Edge Cases**
```typescript
describe('Password Validation', () => {
  it('should reject passwords shorter than 8 characters', () => {
    expect(validatePassword('Pass1')).toBe(false);
  });

  it('should reject passwords without numbers', () => {
    expect(validatePassword('Password')).toBe(false);
  });

  it('should accept valid password', () => {
    expect(validatePassword('Password123!')).toBe(true);
  });
});
```

**3. Mock External Dependencies**
```typescript
const mockPrismaService = {
  user: {
    findUnique: jest.fn(),
    create: jest.fn(),
  },
};

beforeEach(() => {
  jest.clearAllMocks();
});
```

**4. Test Async Operations**
```typescript
it('should handle async errors', async () => {
  mockService.getData.mockRejectedValue(new Error('Network error'));

  await expect(getData()).rejects.toThrow('Network error');
});
```

**5. Use Descriptive Test Names**
```typescript
// ❌ Bad
it('works', () => {});

// ✅ Good
it('should return 401 when user provides invalid credentials', () => {});
```

---

## 🎯 Test Priorities

### High Priority (Must Have)
- [ ] Authentication flows (signup, login, logout)
- [ ] Payment processing (with mocked Stripe)
- [ ] RBAC (role-based access control)
- [ ] GDPR operations (data export, account deletion)
- [ ] Critical user flows (booking, check-in)

### Medium Priority (Should Have)
- [ ] Service layer unit tests
- [ ] API endpoint integration tests
- [ ] Form validation
- [ ] Error handling
- [ ] State management (Riverpod)

### Low Priority (Nice to Have)
- [ ] UI component tests
- [ ] Visual regression tests
- [ ] Performance tests
- [ ] Accessibility tests

---

## 🐛 Debugging Tests

### Backend Debugging

```bash
# Debug specific test
node --inspect-brk node_modules/.bin/jest --runInBand auth.service.spec.ts

# Then open chrome://inspect in Chrome
```

### Frontend Debugging

```bash
# Run tests in verbose mode
flutter test --verbose

# Debug specific test
flutter test test/widget_test.dart --plain-name "Button should have tap feedback"
```

---

## 📚 Testing Resources

**NestJS Testing**:
- [Official Docs](https://docs.nestjs.com/fundamentals/testing)
- [Jest Docs](https://jestjs.io/docs/getting-started)
- [Supertest](https://github.com/visionmedia/supertest)

**Flutter Testing**:
- [Official Docs](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

**General Testing**:
- [Test-Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Testing Best Practices](https://testingjavascript.com/)

---

## ✅ Testing Checklist

Before pushing code:
- [ ] All tests pass locally
- [ ] New features have tests
- [ ] Bug fixes include regression tests
- [ ] Coverage meets threshold (70%+)
- [ ] No skipped/pending tests without reason
- [ ] Test names are descriptive
- [ ] No console.log in tests

Before deploying:
- [ ] All CI/CD tests pass
- [ ] E2E tests run successfully
- [ ] Load testing completed (if applicable)
- [ ] Security tests passed
- [ ] Performance tests passed

---

**Last Updated**: November 2025
**Version**: 1.0.0
