import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';

import { PrismaService } from '../../database/prisma.service';
import { AuthService } from './auth.service';

type MockPrismaService = {
  user: {
    findUnique: jest.Mock;
    update: jest.Mock;
  };
  refreshSession: {
    create: jest.Mock;
    findUnique: jest.Mock;
    update: jest.Mock;
    updateMany: jest.Mock;
  };
};

describe('AuthService', () => {
  let authService: AuthService;
  let jwtService: JwtService;
  let prisma: MockPrismaService;
  let passwordHash: string;

  beforeEach(async () => {
    passwordHash = await argon2.hash('Correct#123');
    jwtService = new JwtService();
    prisma = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      refreshSession: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
    };

    const configService = {
      get: jest.fn((key: string) => {
        if (key === 'JWT_ACCESS_TOKEN_SECRET') {
          return 'unit-test-jwt-secret';
        }

        if (key === 'JWT_ACCESS_TOKEN_EXPIRES_IN') {
          return '15m';
        }

        return undefined;
      }),
    } as unknown as ConfigService;

    authService = new AuthService(
      prisma as unknown as PrismaService,
      jwtService,
      configService,
    );
  });

  it('登录成功返回 token/user/roles/permissions/menus，且 access token payload 不包含 permissions', async () => {
    const activeUser = createUserRecord({
      passwordHash,
      userRoles: [
        createUserRole({
          role: createRole({
            rolePermissions: [
              createRolePermission({
                permission: createPermission({
                  code: 'menu:dashboard',
                  name: '工作台菜单',
                  type: 'MENU',
                  module: 'dashboard',
                }),
              }),
              createRolePermission({
                permission: createPermission({
                  code: 'api:auth:session',
                  name: '当前会话快照接口',
                  type: 'API',
                  module: 'system',
                  sortOrder: 1510,
                }),
              }),
            ],
          }),
        }),
      ],
    });

    prisma.user.findUnique.mockResolvedValue(activeUser);
    prisma.user.update.mockResolvedValue(activeUser);
    prisma.refreshSession.create.mockImplementation(({ data }) =>
      Promise.resolve({
        id: 'session_1',
        ...data,
      }),
    );

    const data = await authService.login(
      { username: 'admin', password: 'Correct#123' },
      { ipAddress: '127.0.0.1', userAgent: 'jest' },
    );

    expect(data.accessToken).toEqual(expect.any(String));
    expect(data.refreshToken).toMatch(/^session_1\./);
    expect(data.user).toEqual({
      id: 'user-1',
      username: 'admin',
      status: 'ACTIVE',
      profile: {
        displayName: '系统管理员',
        phone: null,
        email: null,
        avatarUrl: null,
        departmentName: null,
        postName: null,
      },
    });
    expect(data.roles).toEqual([
      {
        id: 1,
        code: 'SUPER_ADMIN',
        name: '超级管理员',
        description: '系统维护者',
        isSystem: true,
        isActive: true,
      },
    ]);
    expect(data.permissions.map((permission) => permission.code)).toEqual([
      'menu:dashboard',
      'api:auth:session',
    ]);
    expect(data.menus).toEqual([
      {
        key: 'dashboard',
        title: '工作台',
        route: '/',
        icon: 'LayoutDashboard',
        permissionCode: 'menu:dashboard',
        sortOrder: 10,
        children: [],
      },
    ]);

    const payload = jwtService.decode(data.accessToken) as Record<
      string,
      unknown
    >;
    expect(payload.sub).toBe('user-1');
    expect(payload.username).toBe('admin');
    expect(payload.tokenVersion).toBe(0);
    expect(payload.permissions).toBeUndefined();
    expect(payload.roles).toBeUndefined();
  });

  it.each(['DISABLED', 'LOCKED'] as const)(
    '%s 用户登录失败并返回 USER_DISABLED',
    async (status) => {
      prisma.user.findUnique.mockResolvedValue(
        createUserRecord({ passwordHash, status }),
      );

      await expect(
        authService.login({ username: 'admin', password: 'Correct#123' }),
      ).rejects.toMatchObject({
        response: {
          code: 'USER_DISABLED',
          data: null,
        },
        status: 403,
      });
    },
  );

  it('无启用角色登录返回 NO_ACTIVE_ROLE', async () => {
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        passwordHash,
        userRoles: [
          createUserRole({
            role: createRole({ isActive: false }),
          }),
        ],
      }),
    );

    await expect(
      authService.login({ username: 'admin', password: 'Correct#123' }),
    ).rejects.toMatchObject({
      response: {
        code: 'NO_ACTIVE_ROLE',
        data: null,
      },
      status: 403,
    });
  });

  it('菜单 route 与前端 AppRoutes 保持一致', async () => {
    const activeUser = createUserRecord({
      passwordHash,
      userRoles: [
        createUserRole({
          role: createRole({
            rolePermissions: [
              createRolePermission({
                permission: createPermission({
                  code: 'menu:dashboard',
                  name: '工作台菜单',
                  type: 'MENU',
                  module: 'dashboard',
                  sortOrder: 10,
                }),
              }),
              createRolePermission({
                permission: createPermission({
                  id: 2,
                  code: 'menu:base-data',
                  name: '基础数据菜单',
                  type: 'MENU',
                  module: 'base-data',
                  sortOrder: 20,
                }),
              }),
              createRolePermission({
                permission: createPermission({
                  id: 3,
                  code: 'menu:settings',
                  name: '系统设置菜单',
                  type: 'MENU',
                  module: 'system',
                  sortOrder: 30,
                }),
              }),
            ],
          }),
        }),
      ],
    });

    prisma.user.findUnique.mockResolvedValue(activeUser);

    const snapshot = await authService.getSessionSnapshot('user-1');
    const routesByPermission = Object.fromEntries(
      snapshot.menus.map((menu) => [
        menu.permissionCode.replace('menu:', ''),
        menu.route,
      ]),
    );

    expect(routesByPermission).toEqual({
      dashboard: '/',
      'base-data': '/base-data',
      settings: '/settings',
    });
  });

  it('refresh token 轮换后旧 token 再刷新失败', async () => {
    const activeUser = createUserRecord({
      passwordHash,
      userRoles: [
        createUserRole({
          role: createRole({
            rolePermissions: [
              createRolePermission({
                permission: createPermission({
                  code: 'menu:dashboard',
                  name: '工作台菜单',
                  type: 'MENU',
                  module: 'dashboard',
                }),
              }),
            ],
          }),
        }),
      ],
    });
    let refreshSessionRecord: Record<string, unknown> | undefined;

    prisma.user.findUnique.mockResolvedValue(activeUser);
    prisma.user.update.mockResolvedValue(activeUser);
    prisma.refreshSession.create.mockImplementation(({ data }) => {
      refreshSessionRecord = {
        id: 'session_rotate',
        ...data,
        revokedAt: null,
        expiresAt: new Date(Date.now() + 60_000),
        user: activeUser,
      };

      return Promise.resolve(refreshSessionRecord);
    });
    prisma.refreshSession.findUnique.mockImplementation(() =>
      Promise.resolve(refreshSessionRecord),
    );
    prisma.refreshSession.updateMany.mockImplementation(({ data, where }) => {
      if (
        refreshSessionRecord?.id !== where.id ||
        refreshSessionRecord.refreshTokenHash !== where.refreshTokenHash ||
        refreshSessionRecord.revokedAt !== where.revokedAt
      ) {
        return Promise.resolve({ count: 0 });
      }

      refreshSessionRecord = {
        ...refreshSessionRecord,
        ...data,
      };

      return Promise.resolve({ count: 1 });
    });

    const loginData = await authService.login({
      username: 'admin',
      password: 'Correct#123',
    });
    const rotated = await authService.refresh({
      refreshToken: loginData.refreshToken,
    });

    expect(rotated.refreshToken).toMatch(/^session_rotate\./);
    expect(rotated.refreshToken).not.toBe(loginData.refreshToken);

    await expect(
      authService.refresh({ refreshToken: loginData.refreshToken }),
    ).rejects.toMatchObject({
      response: {
        code: 'TOKEN_REVOKED',
        data: null,
      },
      status: 401,
    });
  });

  it('refresh token 使用 CAS 轮换，旧 token 第二次消费返回 TOKEN_REVOKED', async () => {
    const activeUser = createUserRecord({
      passwordHash,
      userRoles: [
        createUserRole({
          role: createRole({
            rolePermissions: [
              createRolePermission({
                permission: createPermission({
                  code: 'menu:dashboard',
                  name: '工作台菜单',
                  type: 'MENU',
                  module: 'dashboard',
                }),
              }),
            ],
          }),
        }),
      ],
    });
    let refreshSessionRecord: Record<string, unknown> | undefined;
    let issuedRefreshTokenHash = '';

    prisma.user.findUnique.mockResolvedValue(activeUser);
    prisma.user.update.mockResolvedValue(activeUser);
    prisma.refreshSession.create.mockImplementation(({ data }) => {
      issuedRefreshTokenHash = data.refreshTokenHash;
      refreshSessionRecord = {
        id: 'session_cas',
        ...data,
        revokedAt: null,
        expiresAt: new Date(Date.now() + 60_000),
        user: activeUser,
      };

      return Promise.resolve(refreshSessionRecord);
    });
    prisma.refreshSession.findUnique.mockImplementation(() =>
      Promise.resolve(refreshSessionRecord),
    );
    prisma.refreshSession.updateMany
      .mockResolvedValueOnce({ count: 1 })
      .mockResolvedValueOnce({ count: 0 });

    const loginData = await authService.login({
      username: 'admin',
      password: 'Correct#123',
    });
    const firstRefresh = await authService.refresh({
      refreshToken: loginData.refreshToken,
    });

    expect(firstRefresh.refreshToken).toMatch(/^session_cas\./);
    expect(firstRefresh.refreshToken).not.toBe(loginData.refreshToken);
    expect(prisma.refreshSession.updateMany).toHaveBeenNthCalledWith(1, {
      where: {
        id: 'session_cas',
        refreshTokenHash: issuedRefreshTokenHash,
        revokedAt: null,
      },
      data: {
        refreshTokenHash: expect.any(String),
      },
    });

    await expect(
      authService.refresh({ refreshToken: loginData.refreshToken }),
    ).rejects.toMatchObject({
      response: {
        code: 'TOKEN_REVOKED',
        data: null,
      },
      status: 401,
    });
    expect(prisma.refreshSession.updateMany).toHaveBeenNthCalledWith(2, {
      where: {
        id: 'session_cas',
        refreshTokenHash: issuedRefreshTokenHash,
        revokedAt: null,
      },
      data: {
        refreshTokenHash: expect.any(String),
      },
    });
  });

  it('refresh token 签发后的 tokenVersion 变更会返回 TOKEN_REVOKED', async () => {
    const issuedUser = createUserRecord({
      passwordHash,
      tokenVersion: 0,
      userRoles: [
        createUserRole({
          role: createRole({
            rolePermissions: [
              createRolePermission({
                permission: createPermission({
                  code: 'menu:dashboard',
                  name: '工作台菜单',
                  type: 'MENU',
                  module: 'dashboard',
                }),
              }),
            ],
          }),
        }),
      ],
    });
    let refreshSessionRecord: Record<string, unknown> | undefined;

    prisma.user.findUnique.mockResolvedValue(issuedUser);
    prisma.user.update.mockResolvedValue(issuedUser);
    prisma.refreshSession.create.mockImplementation(({ data }) => {
      refreshSessionRecord = {
        id: 'session_token_version',
        ...data,
        revokedAt: null,
        expiresAt: new Date(Date.now() + 60_000),
        user: issuedUser,
      };

      return Promise.resolve(refreshSessionRecord);
    });
    prisma.refreshSession.findUnique.mockImplementation(() =>
      Promise.resolve({
        ...refreshSessionRecord,
        user: {
          ...issuedUser,
          tokenVersion: 1,
        },
      }),
    );

    const loginData = await authService.login({
      username: 'admin',
      password: 'Correct#123',
    });

    await expect(
      authService.refresh({ refreshToken: loginData.refreshToken }),
    ).rejects.toMatchObject({
      response: {
        code: 'TOKEN_REVOKED',
        data: null,
      },
      status: 401,
    });
  });

  it('logout 空 body 会撤销当前用户所有未撤销 refresh sessions', async () => {
    prisma.refreshSession.updateMany.mockResolvedValue({ count: 2 });

    await expect(authService.logout(createCurrentUser(), {})).resolves.toEqual({
      success: true,
    });

    expect(prisma.refreshSession.updateMany).toHaveBeenCalledTimes(1);
    expect(prisma.refreshSession.updateMany).toHaveBeenCalledWith({
      where: {
        userId: 'user-1',
        revokedAt: null,
      },
      data: {
        revokedAt: expect.any(Date),
      },
    });
  });

  it('logout 空 refreshToken 字符串会撤销当前用户所有未撤销 refresh sessions', async () => {
    prisma.refreshSession.updateMany.mockResolvedValue({ count: 2 });

    await expect(
      authService.logout(createCurrentUser(), { refreshToken: '' }),
    ).resolves.toEqual({
      success: true,
    });

    expect(prisma.refreshSession.updateMany).toHaveBeenCalledTimes(1);
    expect(prisma.refreshSession.updateMany).toHaveBeenCalledWith({
      where: {
        userId: 'user-1',
        revokedAt: null,
      },
      data: {
        revokedAt: expect.any(Date),
      },
    });
  });

  it('logout 带有效 refreshToken 只撤销当前用户该 refresh session', async () => {
    prisma.refreshSession.updateMany.mockResolvedValue({ count: 1 });

    await expect(
      authService.logout(createCurrentUser(), {
        refreshToken: 'session_current.valid-secret',
      }),
    ).resolves.toEqual({
      success: true,
    });

    expect(prisma.refreshSession.updateMany).toHaveBeenCalledTimes(1);
    expect(prisma.refreshSession.updateMany).toHaveBeenCalledWith({
      where: {
        id: 'session_current',
        userId: 'user-1',
        revokedAt: null,
      },
      data: {
        revokedAt: expect.any(Date),
      },
    });
  });

  it('logout 带非法 refreshToken 返回 TOKEN_REVOKED 且不撤销当前用户全部 sessions', async () => {
    await expect(
      authService.logout(createCurrentUser(), {
        refreshToken: 'invalid-refresh-token',
      }),
    ).rejects.toMatchObject({
      response: {
        code: 'TOKEN_REVOKED',
        data: null,
      },
      status: 401,
    });

    expect(prisma.refreshSession.updateMany).not.toHaveBeenCalled();
  });
});

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
    username: 'admin',
    passwordHash: 'hashed-password',
    status: 'ACTIVE',
    tokenVersion: 0,
    profile: {
      displayName: '系统管理员',
      phone: null,
      email: null,
      avatarUrl: null,
      departmentName: null,
      postName: null,
    },
    userRoles: [
      createUserRole({
        role: createRole(),
      }),
    ],
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
    code: 'SUPER_ADMIN',
    name: '超级管理员',
    description: '系统维护者',
    isSystem: true,
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
    id: 1,
    code: 'menu:dashboard',
    name: '工作台菜单',
    type: 'MENU',
    module: 'dashboard',
    description: null,
    sortOrder: 10,
    isActive: true,
    ...overrides,
  };
}
