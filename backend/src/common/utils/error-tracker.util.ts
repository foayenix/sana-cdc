import { Logger } from '@nestjs/common';

/**
 * Error Tracking Utility
 *
 * Centralized error tracking and logging.
 * Ready for integration with Sentry, Rollbar, or other error tracking services.
 *
 * Usage:
 * ErrorTracker.captureException(error, { userId, action: 'payment-processing' });
 * ErrorTracker.captureMessage('Unusual activity detected', 'warning', { userId });
 */
export class ErrorTracker {
  private static readonly logger = new Logger('ErrorTracker');
  private static sentryEnabled = false;

  /**
   * Initialize Sentry or other error tracking service
   * Call this in main.ts during app initialization
   *
   * Example:
   * ErrorTracker.init({
   *   dsn: process.env.SENTRY_DSN,
   *   environment: process.env.NODE_ENV,
   *   release: process.env.APP_VERSION,
   * });
   */
  static init(config: {
    dsn?: string;
    environment?: string;
    release?: string;
  }): void {
    if (!config.dsn) {
      this.logger.warn(
        'Error tracking not initialized - SENTRY_DSN not provided',
      );
      return;
    }

    // Initialize Sentry
    try {
      const Sentry = require('@sentry/node');
      Sentry.init({
        dsn: config.dsn,
        environment: config.environment,
        release: config.release,
        tracesSampleRate: 0.1, // 10% of transactions
      });

      this.sentryEnabled = true;
      this.logger.log('Error tracking initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize Sentry:', error);
    }
  }

  /**
   * Capture an exception
   */
  static captureException(
    error: Error,
    context?: Record<string, any>,
  ): void {
    // Log locally
    this.logger.error(`Exception: ${error.message}`, error.stack);

    // Send to error tracking service
    if (this.sentryEnabled) {
      try {
        const Sentry = require('@sentry/node');
        Sentry.captureException(error, {
          extra: context,
        });
      } catch (err) {
        this.logger.error('Failed to send exception to Sentry:', err);
      }
    }

    // Could also send to custom logging service, Slack, etc.
    this.sendToCustomLogger('error', error.message, {
      stack: error.stack,
      ...context,
    });
  }

  /**
   * Capture a message (for non-error events)
   */
  static captureMessage(
    message: string,
    level: 'info' | 'warning' | 'error' = 'info',
    context?: Record<string, any>,
  ): void {
    // Log locally
    switch (level) {
      case 'error':
        this.logger.error(message);
        break;
      case 'warning':
        this.logger.warn(message);
        break;
      default:
        this.logger.log(message);
    }

    // Send to error tracking service
    if (this.sentryEnabled) {
      try {
        const Sentry = require('@sentry/node');
        Sentry.captureMessage(message, {
          level,
          extra: context,
        });
      } catch (err) {
        this.logger.error('Failed to send message to Sentry:', err);
      }
    }

    this.sendToCustomLogger(level, message, context);
  }

  /**
   * Set user context for error tracking
   * Call this after user authentication
   */
  static setUser(user: {
    id: string;
    email?: string;
    role?: string;
  }): void {
    if (this.sentryEnabled) {
      try {
        const Sentry = require('@sentry/node');
        Sentry.setUser({
          id: user.id,
          email: user.email,
          role: user.role,
        });
      } catch (err) {
        this.logger.error('Failed to set user in Sentry:', err);
      }
    }
  }

  /**
   * Clear user context (e.g., on logout)
   */
  static clearUser(): void {
    if (this.sentryEnabled) {
      try {
        const Sentry = require('@sentry/node');
        Sentry.setUser(null);
      } catch (err) {
        this.logger.error('Failed to clear user in Sentry:', err);
      }
    }
  }

  /**
   * Add breadcrumb for debugging context
   */
  static addBreadcrumb(message: string, data?: Record<string, any>): void {
    if (this.sentryEnabled) {
      try {
        const Sentry = require('@sentry/node');
        Sentry.addBreadcrumb({
          message,
          data,
          timestamp: Date.now() / 1000,
        });
      } catch (err) {
        this.logger.error('Failed to add breadcrumb in Sentry:', err);
      }
    }
  }

  /**
   * Send to custom logging service (CloudWatch, Datadog, etc.)
   */
  private static sendToCustomLogger(
    level: string,
    message: string,
    context?: Record<string, any>,
  ): void {
    // TODO: Implement custom logging service integration
    // Example: Send to CloudWatch Logs, Datadog, etc.
    // This is a placeholder for your custom logging solution
  }
}
