import { Module } from '@nestjs/common';
import { SanaIndexService } from './sana-index.service';
import { SanaIndexController } from './sana-index.controller';

@Module({
  controllers: [SanaIndexController],
  providers: [SanaIndexService],
  exports: [SanaIndexService],
})
export class SanaIndexModule {}
