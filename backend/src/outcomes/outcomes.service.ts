import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OutcomesService {
  constructor(private readonly prisma: PrismaService) {}

  // TODO: Implement outcomes service methods
}
