import { Module } from '@nestjs/common';
import { SessionTypesService } from './session-types.service';
import { SessionTypesController } from './session-types.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [SessionTypesController],
  providers: [SessionTypesService],
  exports: [SessionTypesService],
})
export class SessionTypesModule {}
