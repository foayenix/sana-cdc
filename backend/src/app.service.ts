import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }

  getInfo() {
    return {
      name: 'SANA Wellness Platform API',
      version: '0.1.0',
      description: 'Backend API for SANA - Connecting clients with credible CAM practitioners',
      documentation: '/api/docs',
    };
  }
}
