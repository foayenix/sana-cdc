import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

/**
 * Simple In-Memory Cache Interceptor
 *
 * Caches GET requests in memory for a configurable TTL.
 * For production, consider using Redis or similar distributed cache.
 *
 * Usage:
 * - Apply to specific routes: @UseInterceptors(new CacheInterceptor(60)) // 60 seconds
 * - Or use the @Cacheable decorator for easier syntax
 *
 * Note: This is a basic implementation. For production:
 * - Use Redis for distributed caching across instances
 * - Implement cache invalidation strategies
 * - Add cache warming for frequently accessed data
 */
@Injectable()
export class CacheInterceptor implements NestInterceptor {
  private readonly logger = new Logger('CacheInterceptor');
  private readonly cache = new Map<string, { data: any; expiresAt: number }>();
  private readonly defaultTTL: number;

  constructor(ttlSeconds: number = 60) {
    this.defaultTTL = ttlSeconds * 1000; // Convert to milliseconds

    // Clean up expired entries every 5 minutes
    setInterval(() => this.cleanupExpiredEntries(), 5 * 60 * 1000);
  }

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url } = request;

    // Only cache GET requests
    if (method !== 'GET') {
      return next.handle();
    }

    // Generate cache key
    const cacheKey = this.generateCacheKey(request);

    // Check cache
    const cachedResponse = this.get(cacheKey);
    if (cachedResponse !== null) {
      this.logger.log(`✅ Cache HIT: ${url}`);
      return of(cachedResponse);
    }

    // Cache miss - execute request and cache result
    this.logger.log(`❌ Cache MISS: ${url}`);
    return next.handle().pipe(
      tap((response) => {
        this.set(cacheKey, response, this.defaultTTL);
      }),
    );
  }

  /**
   * Generate unique cache key from request
   */
  private generateCacheKey(request: any): string {
    const { url, query, params } = request;
    const userId = request.user?.userId || 'anonymous';

    // Include user ID for user-specific cached data
    // Include query params and route params for uniqueness
    return `${userId}:${url}:${JSON.stringify(query)}:${JSON.stringify(params)}`;
  }

  /**
   * Get value from cache
   */
  private get(key: string): any | null {
    const entry = this.cache.get(key);

    if (!entry) {
      return null;
    }

    // Check if expired
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }

    return entry.data;
  }

  /**
   * Set value in cache
   */
  private set(key: string, data: any, ttl: number): void {
    this.cache.set(key, {
      data,
      expiresAt: Date.now() + ttl,
    });
  }

  /**
   * Clear entire cache
   */
  public clearAll(): void {
    this.cache.clear();
    this.logger.log('Cache cleared');
  }

  /**
   * Clear cache entries matching pattern
   */
  public clearPattern(pattern: RegExp): void {
    for (const key of this.cache.keys()) {
      if (pattern.test(key)) {
        this.cache.delete(key);
      }
    }
    this.logger.log(`Cache entries matching ${pattern} cleared`);
  }

  /**
   * Clean up expired cache entries
   */
  private cleanupExpiredEntries(): void {
    const now = Date.now();
    let deletedCount = 0;

    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(key);
        deletedCount++;
      }
    }

    if (deletedCount > 0) {
      this.logger.log(`Cleaned up ${deletedCount} expired cache entries`);
    }
  }

  /**
   * Get cache statistics
   */
  public getStats(): { size: number; keys: string[] } {
    return {
      size: this.cache.size,
      keys: Array.from(this.cache.keys()),
    };
  }
}
