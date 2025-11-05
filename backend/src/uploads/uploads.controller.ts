import { Controller } from '@nestjs/common';
import { UploadsService } from './uploads.service';

@Controller('uploads')
export class UploadsController {
  constructor(private readonly UploadsService: UploadsService) {}

  // TODO: Implement uploads controller endpoints
}
