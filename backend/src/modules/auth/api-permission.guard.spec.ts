import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import { PrismaService } from '../../database/prisma.service';
import { ApiPermissionGuard } from './guards/api-permission.guard';

describe('ApiPermissionGuard', () => {
  let reflector: { getAllAndOverride: jest.Mock };
  let prisma: {
    user: {
      findUnique: jest.Mock;
    };
  };
  let guard: ApiPermissionGuard;

  beforeEach(() => {
    reflector = {
      getAllAndOverride: jest.fn(),
    };
    prisma = {
      user: {
        findUnique: jest.fn(),
      },
    };
    guard = new ApiPermissionGuard(
      reflector as unknown as Reflector,
      prisma as unknown as PrismaService,
    );
  });

  it('public route 直接放行', async () => {
    reflector.getAllAndOverride.mockReturnValueOnce(true);

    await expect(guard.canActivate(createContext({}))).resolves.toBe(true);
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('没有 @ApiPermission 元数据时直接放行', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce(false)
      .mockReturnValueOnce(undefined);

    await expect(guard.canActivate(createContext({}))).resolves.toBe(true);
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('启用角色拥有启用 API 权限时放行', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce(false)
      .mockReturnValueOnce(['api:users:list']);
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        userRoles: [
          createUserRole({
            role: createRole({
              rolePermissions: [
                createRolePermission({
                  permission: createPermission({ code: 'api:users:list' }),
                }),
              ],
            }),
          }),
        ],
      }),
    );

    await expect(
      guard.canActivate(createContext({ user: createCurrentUser() })),
    ).resolves.toBe(true);
  });

  it('缺少声明的 API 权限时返回 FORBIDDEN', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce(false)
      .mockReturnValueOnce(['api:users:list']);
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        userRoles: [
          createUserRole({
            role: createRole({
              rolePermissions: [
                createRolePermission({
                  permission: createPermission({ code: 'api:roles:list' }),
                }),
              ],
            }),
          }),
        ],
      }),
    );

    await expect(
      guard.canActivate(createContext({ user: createCurrentUser() })),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
  });

  it('禁用角色上的权限不参与授权', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce(false)
      .mockReturnValueOnce(['api:users:list']);
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        userRoles: [
          createUserRole({
            role: createRole({
              id: 1,
              isActive: false,
              rolePermissions: [
                createRolePermission({
                  permission: createPermission({ code: 'api:users:list' }),
                }),
              ],
            }),
          }),
          createUserRole({
            role: createRole({
              id: 2,
              rolePermissions: [
                createRolePermission({
                  permission: createPermission({ code: 'api:roles:list' }),
                }),
              ],
            }),
          }),
        ],
      }),
    );

    await expect(
      guard.canActivate(createContext({ user: createCurrentUser() })),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
  });

  it('没有任何启用角色时返回 NO_ACTIVE_ROLE', async () => {
    reflector.getAllAndOverride
      .mockReturnValueOnce(false)
      .mockReturnValueOnce(['api:users:list']);
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        userRoles: [
          createUserRole({
            role: createRole({ isActive: false }),
          }),
        ],
      }),
    );

    await expect(
      guard.canActivate(createContext({ user: createCurrentUser() })),
    ).rejects.toMatchObject({
      response: {
        code: 'NO_ACTIVE_ROLE',
        data: null,
      },
      status: 403,
    });
  });
});

function createContext(request: Record<string, unknown>): ExecutionContext {
  return {
    getHandler: jest.fn(),
    getClass: jest.fn(),
    switchToHttp: jest.fn().mockReturnValue({
      getRequest: jest.fn().mockReturnValue(request),
    }),
  } as unknown as ExecutionContext;
}

function createCurrentUser(overrides: Record<string, unknown> = {}) {
  return {
    id: 'user-1',
    username: 'admin',
    status: 'ACTIVE',
    tokenVersion: 0,
    ...overrides,
  };
}

function createUserRecord(overrides: Record<string, unknown> = {}) {
  return {
    id: 'user-1',
    status: 'ACTIVE',
    userRoles: [createUserRole()],
    ...overrides,
  };
}

function createUserRole(overrides: Record<string, unknown> = {}) {
  return {
    role: createRole(),
    ...overrides,
  };
}

function createRole(overrides: Record<string, unknown> = {}) {
  return {
    id: 1,
    isActive: true,
    rolePermissions: [],
    ...overrides,
  };
}

function createRolePermission(overrides: Record<string, unknown> = {}) {
  return {
    permission: createPermission(),
    ...overrides,
  };
}

function createPermission(overrides: Record<string, unknown> = {}) {
  return {
    code: 'api:users:list',
    type: 'API',
    isActive: true,
    ...overrides,
  };
}
