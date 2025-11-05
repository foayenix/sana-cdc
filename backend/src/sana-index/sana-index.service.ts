import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SanaIndexService {
  constructor(private readonly prisma: PrismaService) {}

  // TODO: Implement sana-index service methods
}
