import { Controller } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly NotificationsService: NotificationsService) {}

  // TODO: Implement notifications controller endpoints
}
