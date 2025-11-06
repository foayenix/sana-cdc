import { Controller, Get } from '@nestjs/common';
import { LegalService } from './legal.service';

@Controller('legal')
export class LegalController {
  constructor(private readonly legalService: LegalService) {}

  /**
   * GET /api/legal/privacy-policy
   * Get privacy policy content
   */
  @Get('privacy-policy')
  getPrivacyPolicy() {
    return this.legalService.getPrivacyPolicy();
  }

  /**
   * GET /api/legal/terms-of-service
   * Get terms of service content
   */
  @Get('terms-of-service')
  getTermsOfService() {
    return this.legalService.getTermsOfService();
  }
}
