import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

// DTOs
export interface CreateJournalEntryDto {
  clientId: string;
  content: string;
  mood?: number;
  tags?: string[];
}

export interface UpdateJournalEntryDto {
  content?: string;
  mood?: number;
  tags?: string[];
}

export interface GetJournalEntriesDto {
  clientId: string;
  tags?: string[];
  mood?: number;
  startDate?: Date;
  endDate?: Date;
  limit?: number;
  offset?: number;
}

export interface JournalStatsDto {
  totalEntries: number;
  averageMood: number;
  mostUsedTags: { tag: string; count: number }[];
  moodTrend: { date: string; mood: number }[];
  entriesThisWeek: number;
  entriesThisMonth: number;
}

@Injectable()
export class JournalService {
  constructor(private readonly prisma: PrismaService) {}

  async createEntry(dto: CreateJournalEntryDto) {
    const { clientId, content, mood, tags } = dto;

    if (mood !== undefined && (mood < 1 || mood > 5)) {
      throw new Error('Mood must be between 1 and 5');
    }

    const entry = await this.prisma.journal.create({
      data: { clientId, content, mood, tags: tags || [] },
      include: {
        client: {
          select: {
            id: true,
            userId: true,
            user: { select: { id: true, name: true, email: true } },
          },
        },
      },
    });

    return entry;
  }

  async getEntries(dto: GetJournalEntriesDto) {
    const {
      clientId,
      tags,
      mood,
      startDate,
      endDate,
      limit = 50,
      offset = 0,
    } = dto;

    const where: Prisma.JournalWhereInput = { clientId };

    if (tags && tags.length > 0) {
      where.tags = { hasSome: tags };
    }

    if (mood !== undefined) {
      where.mood = mood;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = startDate;
      if (endDate) where.createdAt.lte = endDate;
    }

    const [entries, total] = await Promise.all([
      this.prisma.journal.findMany({
        where,
        include: {
          client: { select: { id: true, userId: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.journal.count({ where }),
    ]);

    return { entries, total };
  }

  async getEntryById(entryId: string) {
    const entry = await this.prisma.journal.findUnique({
      where: { id: entryId },
      include: {
        client: {
          select: {
            id: true,
            userId: true,
            user: { select: { id: true, name: true, email: true } },
          },
        },
      },
    });

    if (!entry) {
      throw new NotFoundException('Journal entry not found');
    }

    return entry;
  }

  async updateEntry(entryId: string, dto: UpdateJournalEntryDto) {
    const { content, mood, tags } = dto;

    if (mood !== undefined && (mood < 1 || mood > 5)) {
      throw new Error('Mood must be between 1 and 5');
    }

    const entry = await this.prisma.journal.update({
      where: { id: entryId },
      data: { content, mood, tags },
      include: {
        client: { select: { id: true, userId: true } },
      },
    });

    return entry;
  }

  async deleteEntry(entryId: string) {
    await this.prisma.journal.delete({ where: { id: entryId } });
    return { message: 'Journal entry deleted successfully' };
  }

  async getJournalStats(clientId: string): Promise<JournalStatsDto> {
    const entries = await this.prisma.journal.findMany({
      where: { clientId },
      select: { mood: true, tags: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });

    const totalEntries = entries.length;

    const moodEntries = entries.filter((e) => e.mood !== null);
    const averageMood =
      moodEntries.length > 0
        ? moodEntries.reduce((sum, e) => sum + (e.mood || 0), 0) / moodEntries.length
        : 0;

    const tagCounts = new Map<string, number>();
    entries.forEach((entry) => {
      entry.tags.forEach((tag) => {
        tagCounts.set(tag, (tagCounts.get(tag) || 0) + 1);
      });
    });
    const mostUsedTags = Array.from(tagCounts.entries())
      .map(([tag, count]) => ({ tag, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const recentMoodEntries = entries.filter(
      (e) => e.mood !== null && e.createdAt >= thirtyDaysAgo,
    );

    const moodByDate = new Map<string, { sum: number; count: number }>();
    recentMoodEntries.forEach((entry) => {
      const date = entry.createdAt.toISOString().split('T')[0];
      const existing = moodByDate.get(date) || { sum: 0, count: 0 };
      moodByDate.set(date, {
        sum: existing.sum + (entry.mood || 0),
        count: existing.count + 1,
      });
    });

    const moodTrend = Array.from(moodByDate.entries())
      .map(([date, data]) => ({
        date,
        mood: Math.round((data.sum / data.count) * 10) / 10,
      }))
      .sort((a, b) => a.date.localeCompare(b.date));

    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    const entriesThisWeek = entries.filter((e) => e.createdAt >= oneWeekAgo).length;

    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
    const entriesThisMonth = entries.filter((e) => e.createdAt >= oneMonthAgo).length;

    return {
      totalEntries,
      averageMood: Math.round(averageMood * 10) / 10,
      mostUsedTags,
      moodTrend,
      entriesThisWeek,
      entriesThisMonth,
    };
  }

  async searchEntries(clientId: string, searchQuery: string, limit = 20) {
    const entries = await this.prisma.journal.findMany({
      where: {
        clientId,
        content: { contains: searchQuery, mode: 'insensitive' },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return entries;
  }

  async getUniqueTags(clientId: string) {
    const entries = await this.prisma.journal.findMany({
      where: { clientId },
      select: { tags: true },
    });

    const allTags = new Set<string>();
    entries.forEach((entry) => {
      entry.tags.forEach((tag) => allTags.add(tag));
    });

    return Array.from(allTags).sort();
  }
}
