import { UseInterceptors } from '@nestjs/common';
import { CacheInterceptor } from '../interceptors/cache.interceptor';

/**
 * Cacheable Decorator
 *
 * Convenient decorator to cache GET requests on specific routes.
 *
 * Usage:
 * @Cacheable(60) // Cache for 60 seconds
 * @Get('practitioners')
 * async findAll() { ... }
 *
 * @Cacheable(300) // Cache for 5 minutes
 * @Get('practitioners/:id')
 * async findOne(@Param('id') id: string) { ... }
 */
export function Cacheable(ttlSeconds: number = 60) {
  return UseInterceptors(new CacheInterceptor(ttlSeconds));
}
