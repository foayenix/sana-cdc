import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SessionNotesService {
  constructor(private readonly prisma: PrismaService) {}

  // TODO: Implement session-notes service methods
}
