import { ExecutionContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

import { PrismaService } from '../../database/prisma.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

describe('JwtAuthGuard', () => {
  it('tokenVersion 不匹配返回 TOKEN_REVOKED', async () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue(false),
    } as unknown as Reflector;
    const jwtService = {
      verifyAsync: jest.fn().mockResolvedValue({
        sub: 'user-1',
        username: 'admin',
        tokenVersion: 1,
      }),
    } as unknown as JwtService;
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-1',
          username: 'admin',
          status: 'ACTIVE',
          tokenVersion: 2,
        }),
      },
    } as unknown as PrismaService;
    const configService = {
      get: jest.fn().mockReturnValue('unit-test-jwt-secret'),
    } as unknown as ConfigService;
    const guard = new JwtAuthGuard(
      reflector,
      jwtService,
      prisma,
      configService,
    );

    await expect(
      guard.canActivate(
        createHttpContext({
          headers: {
            authorization: 'Bearer access-token',
          },
        }),
      ),
    ).rejects.toMatchObject({
      response: {
        code: 'TOKEN_REVOKED',
        data: null,
      },
      status: 401,
    });
  });
});

function createHttpContext(request: Record<string, unknown>): ExecutionContext {
  return {
    getHandler: jest.fn(),
    getClass: jest.fn(),
    switchToHttp: jest.fn().mockReturnValue({
      getRequest: jest.fn().mockReturnValue(request),
    }),
  } as unknown as ExecutionContext;
}
