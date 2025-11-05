import { Module } from '@nestjs/common';
import { PractitionersService } from './practitioners.service';
import { PractitionersController } from './practitioners.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [PractitionersController],
  providers: [PractitionersService],
  exports: [PractitionersService],
})
export class PractitionersModule {}
