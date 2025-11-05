import { Controller, Get, Patch, Delete, Body, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * GET /api/users/profile
   * Get current user profile
   */
  @Get('profile')
  async getProfile(@CurrentUser() user: any) {
    return this.usersService.getUserById(user.id);
  }

  /**
   * PATCH /api/users/profile
   * Update user profile
   */
  @Patch('profile')
  async updateProfile(
    @CurrentUser() user: any,
    @Body() updateData: { name?: string; profilePhoto?: string },
  ) {
    return this.usersService.updateProfile(user.id, updateData);
  }

  /**
   * DELETE /api/users/account
   * Delete user account
   */
  @Delete('account')
  async deleteAccount(@CurrentUser() user: any) {
    return this.usersService.deleteAccount(user.id);
  }
}
