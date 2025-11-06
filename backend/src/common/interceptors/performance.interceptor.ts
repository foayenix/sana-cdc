import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

/**
 * Performance Monitoring Interceptor
 *
 * Tracks the execution time of HTTP requests and logs slow requests.
 * Can be extended to send metrics to monitoring services (DataDog, New Relic, etc.)
 *
 * Usage:
 * - Apply globally in main.ts: app.useGlobalInterceptors(new PerformanceInterceptor())
 * - Or per controller: @UseInterceptors(PerformanceInterceptor)
 * - Or per route: @UseInterceptors(PerformanceInterceptor)
 */
@Injectable()
export class PerformanceInterceptor implements NestInterceptor {
  private readonly logger = new Logger('PerformanceMonitor');
  private readonly slowRequestThreshold = 1000; // ms - log requests taking longer than this

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, ip, headers } = request;
    const userAgent = headers['user-agent'] || 'unknown';
    const startTime = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const elapsedTime = Date.now() - startTime;
          const response = context.switchToHttp().getResponse();
          const { statusCode } = response;

          // Log performance metrics
          const logMessage = `${method} ${url} ${statusCode} - ${elapsedTime}ms`;

          // Warn on slow requests
          if (elapsedTime > this.slowRequestThreshold) {
            this.logger.warn(
              `⚠️  SLOW REQUEST: ${logMessage} | IP: ${ip} | UA: ${userAgent}`,
            );
          } else if (elapsedTime > 500) {
            this.logger.log(`⏱️  ${logMessage}`);
          }

          // Send to monitoring service (if configured)
          this.sendToMonitoringService({
            method,
            url,
            statusCode,
            elapsedTime,
            ip,
            userAgent,
            timestamp: new Date().toISOString(),
          });
        },
        error: (error) => {
          const elapsedTime = Date.now() - startTime;
          this.logger.error(
            `❌ ERROR: ${method} ${url} - ${elapsedTime}ms | ${error.message}`,
          );

          // Send error to monitoring service
          this.sendErrorToMonitoringService({
            method,
            url,
            elapsedTime,
            error: error.message,
            stack: error.stack,
            ip,
            userAgent,
            timestamp: new Date().toISOString(),
          });
        },
      }),
    );
  }

  /**
   * Send metrics to monitoring service (DataDog, New Relic, etc.)
   * Override this method to integrate with your monitoring service
   */
  private sendToMonitoringService(metrics: any): void {
    // TODO: Integrate with monitoring service
    // Example: datadog.increment('http.request', 1, [`status:${metrics.statusCode}`, `method:${metrics.method}`]);
    // Example: newrelic.recordMetric('Custom/RequestTime', metrics.elapsedTime);
  }

  /**
   * Send errors to monitoring service
   * Override this method to integrate with your error tracking service
   */
  private sendErrorToMonitoringService(errorData: any): void {
    // TODO: Integrate with error tracking (Sentry, Rollbar, etc.)
    // Example: Sentry.captureException(new Error(errorData.error));
  }
}
