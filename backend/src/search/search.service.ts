import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma, VerificationStatus } from '@prisma/client';

export interface SearchFilters {
  query?: string;
  specialties?: string[];
  modalities?: string[];
  postcode?: string;
  maxDistance?: number; // km
  minPrice?: number; // pence
  maxPrice?: number; // pence
  availableFor?: 'in-person' | 'remote' | 'both';
  minRating?: number;
  sortBy?: 'rating' | 'distance' | 'price' | 'experience';
  sortOrder?: 'asc' | 'desc';
  limit?: number;
  offset?: number;
}

export interface PractitionerSearchResult {
  id: string;
  userId: string;
  name: string;
  practiceName?: string;
  bio?: string;
  profilePhoto?: string;
  postcode?: string;
  specialties: string[];
  modalities: string[];
  languagesSpoken: string[];
  yearsOfPractice?: number;
  verifiedBadges: string[];
  sanaIndexScore: number;
  averageRating: number;
  totalReviews: number;
  minPrice?: number; // pence
  maxPrice?: number; // pence
  sessionTypes: Array<{
    id: string;
    name: string;
    duration: number;
    price: number;
    availableFor: string;
  }>;
  distance?: number; // km (if postcode provided)
}

@Injectable()
export class SearchService {
  private readonly logger = new Logger(SearchService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Search for practitioners with advanced filters
   */
  async searchPractitioners(filters: SearchFilters): Promise<{
    results: PractitionerSearchResult[];
    total: number;
    filters: SearchFilters;
  }> {
    const {
      query,
      specialties,
      modalities,
      postcode,
      maxDistance = 50,
      minPrice,
      maxPrice,
      availableFor,
      minRating,
      sortBy = 'rating',
      sortOrder = 'desc',
      limit = 20,
      offset = 0,
    } = filters;

    // Build Prisma where clause
    const where: Prisma.PractitionerProfileWhereInput = {
      verificationStatus: VerificationStatus.APPROVED,
      user: {
        role: 'PRACTITIONER',
      },
    };

    // Text search (name, bio, specialties, modalities)
    if (query && query.trim() !== '') {
      const searchTerm = query.trim().toLowerCase();
      where.OR = [
        { user: { name: { contains: searchTerm, mode: 'insensitive' } } },
        { practiceName: { contains: searchTerm, mode: 'insensitive' } },
        { bio: { contains: searchTerm, mode: 'insensitive' } },
        { specialties: { has: searchTerm } },
        { modalities: { has: searchTerm } },
      ];
    }

    // Filter by specialties
    if (specialties && specialties.length > 0) {
      where.specialties = { hasSome: specialties };
    }

    // Filter by modalities
    if (modalities && modalities.length > 0) {
      where.modalities = { hasSome: modalities };
    }

    // Filter by postcode (basic implementation - in production use PostGIS or external geocoding API)
    if (postcode) {
      // For now, just filter by exact match or prefix
      // In production, you'd calculate actual distance using lat/lng
      where.postcode = { startsWith: postcode.substring(0, 2) };
    }

    // Fetch practitioners with session types
    const practitioners = await this.prisma.practitionerProfile.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            profilePhoto: true,
          },
        },
        sessionTypes: {
          where: { isActive: true },
          select: {
            id: true,
            name: true,
            duration: true,
            price: true,
            availableFor: true,
          },
        },
        reviews: {
          where: { isPublished: true },
          select: {
            rating: true,
          },
        },
      },
    });

    // Apply additional filters and calculate metadata
    let results: PractitionerSearchResult[] = practitioners
      .map((p) => {
        // Calculate average rating
        const ratings = p.reviews.map((r) => r.rating);
        const averageRating =
          ratings.length > 0
            ? ratings.reduce((sum, r) => sum + r, 0) / ratings.length
            : 0;

        // Calculate price range from session types
        const prices = p.sessionTypes.map((st) => st.price);
        const minSessionPrice = prices.length > 0 ? Math.min(...prices) : undefined;
        const maxSessionPrice = prices.length > 0 ? Math.max(...prices) : undefined;

        // Calculate distance (placeholder - in production use actual geocoding)
        let distance: number | undefined;
        if (postcode && p.postcode) {
          distance = this.calculateDistance(postcode, p.postcode);
        }

        return {
          id: p.id,
          userId: p.userId,
          name: p.user.name,
          practiceName: p.practiceName,
          bio: p.bio,
          profilePhoto: p.user.profilePhoto,
          postcode: p.postcode,
          specialties: p.specialties,
          modalities: p.modalities,
          languagesSpoken: p.languagesSpoken,
          yearsOfPractice: p.yearsOfPractice,
          verifiedBadges: p.verifiedBadges,
          sanaIndexScore: p.sanaIndexScore,
          averageRating,
          totalReviews: ratings.length,
          minPrice: minSessionPrice,
          maxPrice: maxSessionPrice,
          sessionTypes: p.sessionTypes,
          distance,
        };
      })
      // Filter by price range
      .filter((p) => {
        if (minPrice !== undefined && p.minPrice !== undefined && p.minPrice < minPrice) {
          return false;
        }
        if (maxPrice !== undefined && p.maxPrice !== undefined && p.maxPrice > maxPrice) {
          return false;
        }
        return true;
      })
      // Filter by availability type
      .filter((p) => {
        if (!availableFor) return true;
        return p.sessionTypes.some((st) => {
          if (availableFor === 'both') return true;
          return st.availableFor === availableFor || st.availableFor === 'both';
        });
      })
      // Filter by minimum rating
      .filter((p) => {
        if (minRating === undefined) return true;
        return p.averageRating >= minRating;
      })
      // Filter by max distance
      .filter((p) => {
        if (!postcode || p.distance === undefined) return true;
        return p.distance <= maxDistance;
      });

    // Sort results
    results = this.sortResults(results, sortBy, sortOrder);

    // Get total before pagination
    const total = results.length;

    // Apply pagination
    results = results.slice(offset, offset + limit);

    this.logger.log(
      `Search completed: ${results.length} results (${total} total) with filters: ${JSON.stringify(filters)}`,
    );

    return {
      results,
      total,
      filters,
    };
  }

  /**
   * Get available filter options (for UI dropdowns)
   */
  async getFilterOptions(): Promise<{
    specialties: string[];
    modalities: string[];
    priceRange: { min: number; max: number };
  }> {
    // Get all unique specialties
    const practitioners = await this.prisma.practitionerProfile.findMany({
      where: { verificationStatus: VerificationStatus.APPROVED },
      select: { specialties: true, modalities: true },
    });

    const specialtiesSet = new Set<string>();
    const modalitiesSet = new Set<string>();

    practitioners.forEach((p) => {
      p.specialties.forEach((s) => specialtiesSet.add(s));
      p.modalities.forEach((m) => modalitiesSet.add(m));
    });

    // Get price range
    const sessionTypes = await this.prisma.sessionType.findMany({
      where: { isActive: true },
      select: { price: true },
    });

    const prices = sessionTypes.map((st) => st.price);
    const minPrice = prices.length > 0 ? Math.min(...prices) : 0;
    const maxPrice = prices.length > 0 ? Math.max(...prices) : 20000; // £200 default max

    return {
      specialties: Array.from(specialtiesSet).sort(),
      modalities: Array.from(modalitiesSet).sort(),
      priceRange: { min: minPrice, max: maxPrice },
    };
  }

  /**
   * Get popular search terms (for autocomplete)
   */
  async getPopularSearchTerms(): Promise<string[]> {
    // In production, this would track actual searches
    // For now, return popular specialties and modalities
    const options = await this.getFilterOptions();
    return [...options.specialties.slice(0, 10), ...options.modalities.slice(0, 10)];
  }

  /**
   * Sort results by specified criteria
   */
  private sortResults(
    results: PractitionerSearchResult[],
    sortBy: string,
    sortOrder: 'asc' | 'desc',
  ): PractitionerSearchResult[] {
    const sorted = [...results];

    sorted.sort((a, b) => {
      let comparison = 0;

      switch (sortBy) {
        case 'rating':
          comparison = a.averageRating - b.averageRating;
          // If ratings are equal, sort by number of reviews
          if (comparison === 0) {
            comparison = a.totalReviews - b.totalReviews;
          }
          break;
        case 'distance':
          if (a.distance !== undefined && b.distance !== undefined) {
            comparison = a.distance - b.distance;
          }
          break;
        case 'price':
          if (a.minPrice !== undefined && b.minPrice !== undefined) {
            comparison = a.minPrice - b.minPrice;
          }
          break;
        case 'experience':
          if (a.yearsOfPractice !== undefined && b.yearsOfPractice !== undefined) {
            comparison = a.yearsOfPractice - b.yearsOfPractice;
          }
          break;
        default:
          comparison = 0;
      }

      return sortOrder === 'asc' ? comparison : -comparison;
    });

    return sorted;
  }

  /**
   * Calculate distance between two postcodes (placeholder)
   * In production, use actual geocoding API or PostGIS
   */
  private calculateDistance(postcode1: string, postcode2: string): number {
    // Placeholder: return random distance for demo
    // In production, use Google Maps API, Postcodes.io, or PostGIS
    const prefix1 = postcode1.substring(0, 2);
    const prefix2 = postcode2.substring(0, 2);

    if (prefix1 === prefix2) {
      return Math.random() * 10; // 0-10 km for same area
    }

    return Math.random() * 50 + 10; // 10-60 km for different areas
  }
}
