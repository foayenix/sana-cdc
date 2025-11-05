import { Controller } from '@nestjs/common';
import { JournalService } from './journal.service';

@Controller('journal')
export class JournalController {
  constructor(private readonly JournalService: JournalService) {}

  // TODO: Implement journal controller endpoints
}
