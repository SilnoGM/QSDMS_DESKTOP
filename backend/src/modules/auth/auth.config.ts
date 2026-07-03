import { HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { JwtSignOptions } from '@nestjs/jwt';

import { throwAuthException } from './auth.errors';

export const DEFAULT_ACCESS_TOKEN_EXPIRES_IN = '15m';
export const DEFAULT_REFRESH_TOKEN_DAYS = 7;

export function getJwtAccessTokenSecret(configService: ConfigService): string {
  const secret = configService.get<string>('JWT_ACCESS_TOKEN_SECRET');

  if (!secret) {
    throwAuthException(
      'UNAUTHORIZED',
      'JWT_ACCESS_TOKEN_SECRET is not configured.',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }

  return secret;
}

export function getJwtAccessTokenExpiresIn(
  configService: ConfigService,
): JwtSignOptions['expiresIn'] {
  return (
    configService.get<string>('JWT_ACCESS_TOKEN_EXPIRES_IN') ??
    DEFAULT_ACCESS_TOKEN_EXPIRES_IN
  ) as JwtSignOptions['expiresIn'];
}

export function createRefreshTokenExpiresAt(now = new Date()): Date {
  return new Date(now.getTime() + DEFAULT_REFRESH_TOKEN_DAYS * 24 * 60 * 60_000);
}
