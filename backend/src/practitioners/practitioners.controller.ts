import { Controller } from '@nestjs/common';
import { PractitionersService } from './practitioners.service';

@Controller('practitioners')
export class PractitionersController {
  constructor(private readonly PractitionersService: PractitionersService) {}

  // TODO: Implement practitioners controller endpoints
}
