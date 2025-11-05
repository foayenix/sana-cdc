import { Controller } from '@nestjs/common';
import { OutcomesService } from './outcomes.service';

@Controller('outcomes')
export class OutcomesController {
  constructor(private readonly OutcomesService: OutcomesService) {}

  // TODO: Implement outcomes controller endpoints
}
