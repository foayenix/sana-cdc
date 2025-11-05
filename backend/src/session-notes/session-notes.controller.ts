import { Controller } from '@nestjs/common';
import { SessionNotesService } from './session-notes.service';

@Controller('session-notes')
export class SessionNotesController {
  constructor(private readonly SessionNotesService: SessionNotesService) {}

  // TODO: Implement session-notes controller endpoints
}
