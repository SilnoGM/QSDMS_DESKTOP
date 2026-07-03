import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { UserStatus } from '@prisma/client';

import { PrismaService } from '../../../database/prisma.service';
import { getJwtAccessTokenSecret } from '../auth.config';
import { throwAuthException } from '../auth.errors';
import { PUBLIC_ROUTE_KEY } from '../decorators/public.decorator';
import { AuthenticatedRequest } from '../models/authenticated-request.model';
import { JwtPayload } from '../models/jwt-payload.model';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublicRoute = this.reflector.getAllAndOverride<boolean>(
      PUBLIC_ROUTE_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (isPublicRoute) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const accessToken = this.extractBearerToken(request);
    const payload = await this.verifyAccessToken(accessToken);
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        username: true,
        status: true,
        tokenVersion: true,
      },
    });

    if (!user) {
      throwAuthException(
        'UNAUTHORIZED',
        'Invalid access token.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    if (user.status !== UserStatus.ACTIVE) {
      throwAuthException(
        'USER_DISABLED',
        'User is disabled or locked.',
        HttpStatus.FORBIDDEN,
      );
    }

    if (payload.tokenVersion !== user.tokenVersion) {
      throwAuthException(
        'TOKEN_REVOKED',
        'Access token has been revoked.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    request.user = {
      id: user.id,
      username: user.username,
      status: user.status,
      tokenVersion: user.tokenVersion,
    };

    return true;
  }

  private extractBearerToken(request: AuthenticatedRequest): string {
    const authorization = request.headers.authorization;

    if (!authorization) {
      throwAuthException(
        'UNAUTHORIZED',
        'Missing Authorization header.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    const [scheme, token] = authorization.split(' ');

    if (scheme !== 'Bearer' || !token) {
      throwAuthException(
        'UNAUTHORIZED',
        'Invalid Authorization header.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    return token;
  }

  private async verifyAccessToken(accessToken: string): Promise<JwtPayload> {
    try {
      return await this.jwtService.verifyAsync<JwtPayload>(accessToken, {
        secret: getJwtAccessTokenSecret(this.configService),
      });
    } catch (error) {
      if (isErrorNamed(error, 'TokenExpiredError')) {
        throwAuthException(
          'TOKEN_EXPIRED',
          'Access token expired.',
          HttpStatus.UNAUTHORIZED,
        );
      }

      throwAuthException(
        'UNAUTHORIZED',
        'Invalid access token.',
        HttpStatus.UNAUTHORIZED,
      );
    }
  }
}

function isErrorNamed(error: unknown, name: string): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'name' in error &&
    error.name === name
  );
}
