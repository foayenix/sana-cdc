import { Controller } from '@nestjs/common';
import { SanaIndexService } from './sana-index.service';

@Controller('sana-index')
export class SanaIndexController {
  constructor(private readonly SanaIndexService: SanaIndexService) {}

  // TODO: Implement sana-index controller endpoints
}
