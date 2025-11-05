import { Module } from '@nestjs/common';
import { SanaIndexService } from './sana-index.service';
import { SanaIndexController } from './sana-index.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [SanaIndexController],
  providers: [SanaIndexService],
  exports: [SanaIndexService],
})
export class SanaIndexModule {}
