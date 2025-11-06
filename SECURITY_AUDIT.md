# SANA CDC Security Audit Checklist

This document provides a comprehensive security audit checklist for the SANA CDC platform before production launch.

**Last Updated**: November 2025
**Audit Version**: 1.0.0
**Compliance**: OWASP Top 10, GDPR, PCI DSS (via Stripe)

---

## 🔐 1. Authentication & Authorization

### 1.1 Password Security
- [x] Passwords hashed with bcrypt (12+ rounds)
- [x] Minimum password length enforced (8 characters)
- [x] Password complexity requirements (letters, numbers)
- [x] No password stored in plain text
- [x] No default/test credentials in production
- [ ] **TODO**: Implement password strength meter in UI
- [ ] **TODO**: Add breach password check (HaveIBeenPwned API)
- [ ] **TODO**: Enforce password rotation policy (optional)

**Location**: `backend/src/auth/auth.service.ts:38-39`

### 1.2 JWT Tokens
- [x] JWT secret is strong (256+ bits)
- [x] Access tokens are short-lived (15 minutes)
- [x] Refresh tokens are long-lived (7 days)
- [x] Tokens include expiration claims
- [x] Tokens signed with HS256 or RS256
- [x] No sensitive data in JWT payload
- [ ] **TODO**: Implement token blacklist for logout
- [ ] **TODO**: Add JWT rotation on refresh

**Location**: `backend/src/auth/auth.module.ts:14-23`

### 1.3 Session Management
- [x] Sessions invalidated on logout
- [x] Last login timestamp tracked
- [x] Concurrent session handling
- [ ] **TODO**: Add session timeout after inactivity
- [ ] **TODO**: Implement "logout all devices" feature

### 1.4 OAuth & Social Login
- [x] Google OAuth implemented securely
- [x] State parameter validated
- [x] Redirect URLs whitelisted
- [x] No access tokens exposed to client

**Location**: `backend/src/auth/auth.service.ts:141-247`

### 1.5 Role-Based Access Control (RBAC)
- [x] Roles defined (CLIENT, PRACTITIONER, ADMIN)
- [x] Role-based guards implemented
- [x] Endpoint access restricted by role
- [x] Principle of least privilege applied
- [ ] **TODO**: Add permission-based access control

**Location**: `backend/src/auth/guards/roles.guard.ts`

---

## 🛡️ 2. API Security

### 2.1 Input Validation
- [x] All inputs validated with class-validator
- [x] Whitelist validation enabled
- [x] No unknown properties accepted
- [x] Type transformation enabled
- [x] SQL injection prevented (Prisma parameterized queries)
- [x] XSS prevention (no HTML rendering of user input)
- [ ] **TODO**: Add request size limits
- [ ] **TODO**: Implement content-type validation

**Location**: `backend/src/main.ts:31-40`

### 2.2 Rate Limiting
- [x] Rate limiting enabled globally
- [x] Throttler configured (10 req/60s)
- [x] Auth endpoints protected
- [ ] **TODO**: Implement IP-based rate limiting
- [ ] **TODO**: Add dynamic rate limits per user tier
- [ ] **TODO**: Configure stricter limits for auth endpoints

**Location**: `backend/src/app.module.ts:42-46`

### 2.3 CORS Configuration
- [x] CORS enabled
- [x] Origin whitelist configured
- [x] Credentials allowed for same origin
- [ ] **TODO**: Restrict to production domain only
- [ ] **TODO**: Add preflight caching

**Location**: `backend/src/main.ts:24-27`

### 2.4 HTTPS Enforcement
- [x] HTTPS redirect in production
- [x] X-Forwarded-Proto header checked
- [ ] **TODO**: Add HSTS headers
- [ ] **TODO**: Implement certificate pinning (mobile)

**Location**: `backend/src/main.ts:46-53`

### 2.5 Security Headers
- [ ] **TODO**: Add helmet middleware
- [ ] **TODO**: Set X-Frame-Options: DENY
- [ ] **TODO**: Set X-Content-Type-Options: nosniff
- [ ] **TODO**: Set X-XSS-Protection: 1; mode=block
- [ ] **TODO**: Set Referrer-Policy: strict-origin-when-cross-origin
- [ ] **TODO**: Add Content Security Policy (CSP)

**Recommendation**:
```typescript
// backend/src/main.ts
import helmet from 'helmet';
app.use(helmet());
```

---

## 💳 3. Payment Security (PCI DSS Compliance)

### 3.1 Stripe Integration
- [x] No card data stored on our servers
- [x] Stripe.js used for client-side tokenization
- [x] Stripe webhooks verify signatures
- [x] Payment intents used (SCA compliant)
- [x] Refunds processed securely
- [x] Stripe Connect for practitioner payouts
- [ ] **TODO**: Add fraud detection alerts
- [ ] **TODO**: Implement 3D Secure for high-value transactions

**Location**: `backend/src/payments/payments.controller.ts:82-113`

### 3.2 Webhook Security
- [x] Webhook signatures verified
- [x] Webhook secret stored securely
- [x] Idempotency handling
- [x] No sensitive data logged
- [ ] **TODO**: Add webhook retry logic
- [ ] **TODO**: Monitor webhook failures

**Location**: `backend/src/payments/payments.controller.ts:100-108`

### 3.3 Financial Data
- [x] Platform fee calculated server-side
- [x] No price manipulation possible from client
- [x] Payment amounts validated
- [x] Audit trail for all transactions
- [ ] **TODO**: Add anomaly detection for unusual payments

---

## 🔒 4. Data Protection & Privacy (GDPR)

### 4.1 Data Encryption
- [x] HTTPS/TLS for data in transit
- [x] Database connection uses SSL
- [x] Passwords hashed (bcrypt)
- [x] JWT secrets stored securely
- [ ] **TODO**: Encrypt sensitive fields at rest (health data)
- [ ] **TODO**: Implement field-level encryption for PII

**Recommendation**:
```typescript
// Encrypt sensitive health data
import { createCipher, createDecipher } from 'crypto';
```

### 4.2 Data Minimization
- [x] Only collect necessary data
- [x] No excessive logging of PII
- [x] JWT payload minimal
- [x] Old sessions cleaned up
- [ ] **TODO**: Implement data retention policy
- [ ] **TODO**: Auto-delete inactive accounts (2+ years)

### 4.3 User Rights (GDPR)
- [x] Account deletion implemented
- [x] Data export functionality
- [x] Password confirmation for deletion
- [x] Deletion logged for audit
- [ ] **TODO**: Add "right to rectification" UI
- [ ] **TODO**: Implement data access request workflow
- [ ] **TODO**: Add consent management for marketing

**Location**: `backend/src/users/users.service.ts:66-170`

### 4.4 Consent & Transparency
- [x] Privacy policy available
- [x] Terms of service available
- [x] Health disclaimer displayed
- [ ] **TODO**: Add GDPR consent checkboxes on signup
- [ ] **TODO**: Implement cookie consent banner
- [ ] **TODO**: Add data processing agreements for practitioners

**Location**: `backend/src/legal/`

### 4.5 Data Access Control
- [x] Users can only access own data
- [x] Practitioners can't see other practitioners' data
- [x] Admins have limited access
- [x] Session notes private to practitioner/client
- [x] Health data not shared without consent

---

## 🗄️ 5. Database Security

### 5.1 SQL Injection Prevention
- [x] Prisma ORM used (parameterized queries)
- [x] No raw SQL queries
- [x] No string concatenation for queries
- [x] All inputs validated before DB operations

**Location**: All `*.service.ts` files using Prisma

### 5.2 Database Access
- [x] Database credentials in environment variables
- [x] Least privilege database user
- [x] Database connection pooling
- [x] Connection encrypted (SSL/TLS)
- [ ] **TODO**: Rotate database credentials regularly
- [ ] **TODO**: Enable database query logging (audit)
- [ ] **TODO**: Set up read replicas for scaling

### 5.3 Backup & Recovery
- [ ] **TODO**: Automated daily backups
- [ ] **TODO**: Backup encryption
- [ ] **TODO**: Test restore procedures
- [ ] **TODO**: Offsite backup storage
- [ ] **TODO**: Point-in-time recovery capability

**See**: `DEPLOYMENT.md` for backup procedures

### 5.4 Database Indexes
- [x] 63+ indexes implemented
- [x] Query performance optimized
- [x] No full table scans on large tables
- [x] Composite indexes for common queries

**Location**: `backend/prisma/schema.prisma`

---

## 📁 6. File Upload Security

### 6.1 Upload Validation
- [x] File size limit enforced (10MB)
- [x] File type whitelist (JPG, PNG, PDF)
- [x] MIME type validated
- [x] File extension checked
- [ ] **TODO**: Scan uploads for malware (ClamAV)
- [ ] **TODO**: Generate new filenames (prevent overwrite)
- [ ] **TODO**: Store metadata (original filename, uploader)

**Location**: `backend/src/uploads/uploads.service.ts:101-119`

### 6.2 Storage Security
- [x] Files stored on S3/R2 (not local filesystem)
- [x] Private ACL by default
- [x] Signed URLs for temporary access
- [x] UUID filenames prevent enumeration
- [ ] **TODO**: Set file expiration for temp uploads
- [ ] **TODO**: Implement virus scanning
- [ ] **TODO**: Add watermarking for sensitive documents

**Location**: `backend/src/uploads/uploads.service.ts:29-53`

---

## 🚨 7. Error Handling & Logging

### 7.1 Error Messages
- [x] No stack traces exposed to users
- [x] Generic error messages in production
- [x] No sensitive data in error responses
- [x] HTTP status codes used correctly
- [ ] **TODO**: Standardize error response format
- [ ] **TODO**: Add error correlation IDs

### 7.2 Logging
- [x] Sentry error tracking enabled
- [x] User context logged
- [x] Audit logs for critical actions
- [ ] **TODO**: Log rotation configured
- [ ] **TODO**: Centralized logging (CloudWatch/ELK)
- [ ] **TODO**: Alert on suspicious patterns
- [ ] **TODO**: Mask sensitive data in logs

**Location**: `backend/src/main.ts:8-17`

### 7.3 Monitoring
- [x] Error tracking (Sentry)
- [ ] **TODO**: Performance monitoring (New Relic/Datadog)
- [ ] **TODO**: Uptime monitoring (UptimeRobot)
- [ ] **TODO**: Security event monitoring
- [ ] **TODO**: Failed login attempt tracking

---

## 📱 8. Mobile App Security

### 8.1 API Keys
- [ ] **TODO**: Store API keys in environment config
- [ ] **TODO**: Use separate keys for dev/staging/prod
- [ ] **TODO**: Implement key rotation policy
- [ ] **TODO**: No hardcoded secrets in code

### 8.2 Local Data Storage
- [ ] **TODO**: Use Flutter secure_storage for sensitive data
- [ ] **TODO**: Encrypt local database (Hive/SQLite)
- [ ] **TODO**: Clear cache on logout
- [ ] **TODO**: No PII stored in plain text

### 8.3 Network Security
- [ ] **TODO**: Certificate pinning for API
- [ ] **TODO**: Disable debugging in production builds
- [ ] **TODO**: Code obfuscation enabled
- [ ] **TODO**: Root/jailbreak detection

### 8.4 Biometric Authentication
- [ ] **TODO**: Support Face ID/Touch ID
- [ ] **TODO**: Fallback to password
- [ ] **TODO**: Biometric data never leaves device

---

## 🔍 9. Security Testing

### 9.1 Automated Testing
- [x] Unit tests for critical services
- [x] Integration tests for API endpoints
- [x] E2E tests for user flows
- [ ] **TODO**: Security-specific test cases
- [ ] **TODO**: Dependency vulnerability scanning (npm audit)
- [ ] **TODO**: SAST (Static Application Security Testing)
- [ ] **TODO**: DAST (Dynamic Application Security Testing)

**Location**: `backend/test/`

### 9.2 Manual Testing
- [ ] **TODO**: Penetration testing (OWASP Top 10)
- [ ] **TODO**: Authentication bypass testing
- [ ] **TODO**: Authorization testing
- [ ] **TODO**: Input fuzzing
- [ ] **TODO**: Session management testing

### 9.3 Third-Party Assessment
- [ ] **TODO**: External security audit
- [ ] **TODO**: Penetration test by security firm
- [ ] **TODO**: Code review by security expert
- [ ] **TODO**: Compliance audit (GDPR, PCI)

---

## 🛠️ 10. Dependency Management

### 10.1 Package Security
- [x] Dependencies defined in package.json
- [x] Lock files committed (package-lock.json)
- [ ] **TODO**: Run `npm audit` weekly
- [ ] **TODO**: Update dependencies monthly
- [ ] **TODO**: Use Snyk or Dependabot
- [ ] **TODO**: Whitelist trusted packages only

**Current Command**:
```bash
npm audit --production
npm audit fix
```

### 10.2 Supply Chain Security
- [ ] **TODO**: Verify package signatures
- [ ] **TODO**: Use npm ci in production
- [ ] **TODO**: Pin exact versions (no ^/~)
- [ ] **TODO**: Review package permissions

---

## 📋 11. Compliance Checklist

### 11.1 GDPR Compliance
- [x] Privacy policy published
- [x] Data export functionality
- [x] Account deletion
- [x] Consent tracking
- [x] Data minimization
- [x] Encryption in transit
- [ ] **TODO**: Data Protection Impact Assessment (DPIA)
- [ ] **TODO**: Appoint Data Protection Officer (DPO)
- [ ] **TODO**: GDPR training for team
- [ ] **TODO**: Breach notification procedures

### 11.2 UK Data Protection Act 2018
- [x] Lawful basis for processing (legitimate interest)
- [x] Data subject rights implemented
- [x] Transparent data processing
- [ ] **TODO**: Register with ICO
- [ ] **TODO**: Document processing activities

### 11.3 Health Data Regulations
- [x] Health disclaimer prominent
- [x] "Not medical advice" clearly stated
- [x] No medical claims made
- [ ] **TODO**: Review with legal counsel
- [ ] **TODO**: Obtain professional indemnity insurance

---

## 🚀 12. Deployment Security

### 12.1 Environment Variables
- [x] All secrets in .env files
- [x] .env files in .gitignore
- [x] No secrets in version control
- [x] Separate configs for dev/staging/prod
- [ ] **TODO**: Use secret management (AWS Secrets Manager/Vault)
- [ ] **TODO**: Rotate secrets quarterly

### 12.2 CI/CD Security
- [ ] **TODO**: Security scanning in pipeline
- [ ] **TODO**: Automated testing required for deployment
- [ ] **TODO**: Code review required before merge
- [ ] **TODO**: Signed commits enforced

### 12.3 Infrastructure
- [ ] **TODO**: WAF (Web Application Firewall) enabled
- [ ] **TODO**: DDoS protection (Cloudflare)
- [ ] **TODO**: Network segmentation
- [ ] **TODO**: Firewall rules configured
- [ ] **TODO**: SSH key-based access only

---

## ✅ Pre-Launch Security Checklist

**Critical (Must Fix Before Launch)**:
- [ ] Enable Helmet security headers
- [ ] Implement HSTS
- [ ] Add CSP (Content Security Policy)
- [ ] Set up automated backups
- [ ] Configure log monitoring and alerts
- [ ] Run full npm audit and fix issues
- [ ] External penetration test
- [ ] Legal review of Privacy Policy/Terms
- [ ] GDPR compliance verification

**High Priority (Fix Within 30 Days)**:
- [ ] Implement password breach checking
- [ ] Add fraud detection for payments
- [ ] Set up SIEM (Security Information and Event Management)
- [ ] Configure automated vulnerability scanning
- [ ] Implement data retention policies
- [ ] Add file upload malware scanning

**Medium Priority (Fix Within 90 Days)**:
- [ ] Certificate pinning for mobile
- [ ] Biometric authentication
- [ ] Advanced rate limiting
- [ ] Database encryption at rest
- [ ] Security awareness training for team

---

## 📊 Security Metrics to Track

1. **Failed Login Attempts**: Monitor for brute force attacks
2. **API Error Rates**: Unusual patterns may indicate attacks
3. **Payment Failures**: Track for fraud detection
4. **File Upload Rejections**: Monitor for malicious uploads
5. **Rate Limit Hits**: Identify abuse patterns
6. **Session Duration**: Detect session hijacking
7. **GDPR Requests**: Track data access/deletion requests
8. **Security Incidents**: Log and analyze all incidents

---

## 🔗 Security Resources

**OWASP Resources**:
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)

**Compliance**:
- [ICO GDPR Guide](https://ico.org.uk/for-organisations/guide-to-data-protection/)
- [PCI DSS Standards](https://www.pcisecuritystandards.org/)
- [Stripe Security Guide](https://stripe.com/docs/security/guide)

**Tools**:
- **npm audit**: Built-in dependency vulnerability scanner
- **Snyk**: Continuous security monitoring
- **SonarQube**: Code quality and security analysis
- **OWASP ZAP**: Web application security scanner
- **Burp Suite**: Security testing platform

---

**Audit Completed By**: _________________
**Date**: _________________
**Next Audit Due**: _________________
**Sign Off**: _________________

---

**Last Updated**: November 2025
**Version**: 1.0.0
