import {
  Controller,
  Get,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
  UseGuards,
} from '@nestjs/common';
import { SearchService, SearchFilters } from './search.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  /**
   * Search for practitioners with advanced filters
   * GET /api/search/practitioners?query=massage&specialties=massage,acupuncture&minPrice=5000&maxPrice=15000
   */
  @Get('practitioners')
  async searchPractitioners(
    @Query('query') query?: string,
    @Query('specialties') specialties?: string,
    @Query('modalities') modalities?: string,
    @Query('postcode') postcode?: string,
    @Query('maxDistance', new DefaultValuePipe(50), ParseIntPipe) maxDistance?: number,
    @Query('minPrice', new DefaultValuePipe(0), ParseIntPipe) minPrice?: number,
    @Query('maxPrice', new DefaultValuePipe(100000), ParseIntPipe) maxPrice?: number,
    @Query('availableFor') availableFor?: 'in-person' | 'remote' | 'both',
    @Query('minRating', new DefaultValuePipe(0), ParseIntPipe) minRating?: number,
    @Query('sortBy', new DefaultValuePipe('rating')) sortBy?: 'rating' | 'distance' | 'price' | 'experience',
    @Query('sortOrder', new DefaultValuePipe('desc')) sortOrder?: 'asc' | 'desc',
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset?: number,
  ) {
    const filters: SearchFilters = {
      query,
      specialties: specialties ? specialties.split(',') : undefined,
      modalities: modalities ? modalities.split(',') : undefined,
      postcode,
      maxDistance,
      minPrice,
      maxPrice,
      availableFor,
      minRating,
      sortBy,
      sortOrder,
      limit,
      offset,
    };

    return await this.searchService.searchPractitioners(filters);
  }

  /**
   * Get available filter options for the search UI
   * GET /api/search/filter-options
   */
  @Get('filter-options')
  async getFilterOptions() {
    return await this.searchService.getFilterOptions();
  }

  /**
   * Get popular search terms for autocomplete
   * GET /api/search/popular-terms
   */
  @Get('popular-terms')
  async getPopularSearchTerms() {
    const terms = await this.searchService.getPopularSearchTerms();
    return { terms };
  }
}
