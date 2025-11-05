import { Controller } from '@nestjs/common';
import { AppointmentsService } from './appointments.service';

@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly AppointmentsService: AppointmentsService) {}

  // TODO: Implement appointments controller endpoints
}
