import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';

import type { ApiResponse } from '../../common/interfaces/api-response.interface';
import { AuthService } from './auth.service';
import type { AuthRequestContext } from './auth.service';
import { CurrentUser } from './decorators/current-user.decorator';
import { Public } from './decorators/public.decorator';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import type {
  AuthPermission,
  AuthSessionSnapshot,
  AuthUser,
  LoginResult,
  LogoutResult,
} from './models/auth-session.model';
import type { CurrentUserPayload } from './models/current-user.model';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('login')
  async login(
    @Body() dto: LoginDto,
    @Req() request: Request,
  ): Promise<ApiResponse<LoginResult>> {
    return this.success(
      'AUTH_LOGIN_SUCCESS',
      'login succeeded',
      await this.authService.login(dto, this.createRequestContext(request)),
    );
  }

  @Public()
  @Post('refresh')
  async refresh(
    @Body() dto: RefreshTokenDto,
  ): Promise<ApiResponse<LoginResult>> {
    return this.success(
      'AUTH_REFRESH_SUCCESS',
      'refresh succeeded',
      await this.authService.refresh(dto),
    );
  }

  @Post('logout')
  async logout(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() dto: LogoutDto,
  ): Promise<ApiResponse<LogoutResult>> {
    return this.success(
      'AUTH_LOGOUT_SUCCESS',
      'logout succeeded',
      await this.authService.logout(currentUser, dto),
    );
  }

  @Get('me')
  async me(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<AuthUser>> {
    return this.success(
      'AUTH_ME_SUCCESS',
      'current user loaded',
      await this.authService.getMe(currentUser),
    );
  }

  @Get('permissions')
  async permissions(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<AuthPermission[]>> {
    return this.success(
      'AUTH_PERMISSIONS_SUCCESS',
      'permissions loaded',
      await this.authService.getPermissions(currentUser),
    );
  }

  @Get('session')
  async session(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ApiResponse<AuthSessionSnapshot>> {
    return this.success(
      'AUTH_SESSION_SUCCESS',
      'session loaded',
      await this.authService.getSessionSnapshot(currentUser.id),
    );
  }

  private createRequestContext(request: Request): AuthRequestContext {
    const userAgentHeader = request.headers['user-agent'];

    return {
      ipAddress: request.ip,
      userAgent: Array.isArray(userAgentHeader)
        ? userAgentHeader.join(', ')
        : userAgentHeader,
    };
  }

  private success<T>(
    code: string,
    message: string,
    data: T,
  ): ApiResponse<T> {
    return {
      code,
      message,
      data,
    };
  }
}
