import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SessionTypesService {
  constructor(private readonly prisma: PrismaService) {}

  // TODO: Implement session-types service methods
}
