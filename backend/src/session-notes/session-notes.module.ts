import { Module } from '@nestjs/common';
import { SessionNotesService } from './session-notes.service';
import { SessionNotesController } from './session-notes.controller';

@Module({
  controllers: [SessionNotesController],
  providers: [SessionNotesService],
  exports: [SessionNotesService],
})
export class SessionNotesModule {}
