import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class LegalService {
  private privacyPolicy: string;
  private termsOfService: string;

  constructor() {
    // Load legal documents on service initialization
    this.loadDocuments();
  }

  private loadDocuments() {
    const privacyPath = path.join(__dirname, 'privacy-policy.md');
    const termsPath = path.join(__dirname, 'terms-of-service.md');

    this.privacyPolicy = fs.readFileSync(privacyPath, 'utf-8');
    this.termsOfService = fs.readFileSync(termsPath, 'utf-8');

    // Replace date placeholder
    const currentDate = new Date().toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
    });

    this.privacyPolicy = this.privacyPolicy.replace('{{ date }}', currentDate);
    this.termsOfService = this.termsOfService.replace('{{ date }}', currentDate);
  }

  getPrivacyPolicy() {
    return {
      content: this.privacyPolicy,
      lastUpdated: new Date().toISOString(),
    };
  }

  getTermsOfService() {
    return {
      content: this.termsOfService,
      lastUpdated: new Date().toISOString(),
    };
  }
}
