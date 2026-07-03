import { UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';

import { PrismaService } from '../../database/prisma.service';
import { UsersService } from './users.service';

describe('UsersService', () => {
  let prisma: {
    $transaction: jest.Mock;
    $queryRaw: jest.Mock;
    user: Record<string, jest.Mock>;
    role: Record<string, jest.Mock>;
    userRole: Record<string, jest.Mock>;
    auditLog: Record<string, jest.Mock>;
  };
  let service: UsersService;

  beforeEach(() => {
    prisma = createPrismaMock();
    prisma.$transaction.mockImplementation((callback) => callback(prisma));
    service = new UsersService(prisma as unknown as PrismaService);
  });

  it.each([UserStatus.DISABLED, UserStatus.LOCKED])(
    '%s 会递增 tokenVersion',
    async (status) => {
      prisma.user.findUnique.mockResolvedValue(createUserRecord());
      prisma.user.update.mockResolvedValue(
        createUserRecord({ status, tokenVersion: 8 }),
      );
      prisma.auditLog.create.mockResolvedValue({});

      const result = await service.updateStatus(
        'target-user',
        { status },
        createActor(),
      );

      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'target-user' },
        data: {
          status,
          tokenVersion: { increment: 1 },
        },
        include: expect.any(Object),
      });
      expect(result.tokenVersion).toBeUndefined();
      expect(result.status).toBe(status);
    },
  );

  it('恢复 ACTIVE 不降低 tokenVersion', async () => {
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({ status: UserStatus.DISABLED, tokenVersion: 8 }),
    );
    prisma.user.update.mockResolvedValue(
      createUserRecord({ status: UserStatus.ACTIVE, tokenVersion: 8 }),
    );
    prisma.auditLog.create.mockResolvedValue({});

    await service.updateStatus(
      'target-user',
      { status: UserStatus.ACTIVE },
      createActor(),
    );

    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'target-user' },
      data: {
        status: UserStatus.ACTIVE,
      },
      include: expect.any(Object),
    });
  });

  it('不能禁用最后一个有效 SUPER_ADMIN', async () => {
    prisma.user.findUnique.mockResolvedValue(createEffectiveSuperAdmin());
    prisma.user.count.mockResolvedValue(1);

    await expect(
      service.updateStatus(
        'target-user',
        { status: UserStatus.DISABLED },
        createActor(),
      ),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
    expect(prisma.user.update).not.toHaveBeenCalled();
  });

  it('禁用有效 SUPER_ADMIN 前先在事务内获取 advisory lock', async () => {
    prisma.user.findUnique.mockResolvedValue(createEffectiveSuperAdmin());
    prisma.user.count.mockResolvedValue(2);
    prisma.user.update.mockResolvedValue(
      createEffectiveSuperAdmin({ status: UserStatus.DISABLED }),
    );
    prisma.auditLog.create.mockResolvedValue({});

    await service.updateStatus(
      'target-user',
      { status: UserStatus.DISABLED },
      createActor(),
    );

    expect(getRawSqlText(prisma.$queryRaw.mock.calls[0]?.[0])).toContain(
      'pg_advisory_xact_lock',
    );
    expect(prisma.$queryRaw.mock.invocationCallOrder[0]).toBeLessThan(
      prisma.user.count.mock.invocationCallOrder[0],
    );
    expect(prisma.user.count.mock.invocationCallOrder[0]).toBeLessThan(
      prisma.user.update.mock.invocationCallOrder[0],
    );
  });

  it('分配角色不能移除最后有效 SUPER_ADMIN 绑定', async () => {
    prisma.user.findUnique.mockResolvedValue(createEffectiveSuperAdmin());
    prisma.user.count.mockResolvedValue(1);
    prisma.role.findMany.mockResolvedValue([
      createRole({ id: 2, code: 'ADMIN' }),
    ]);

    await expect(
      service.assignRoles('target-user', { roleIds: [2] }, createActor()),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
    expect(prisma.userRole.deleteMany).not.toHaveBeenCalled();
  });

  it('移除有效 SUPER_ADMIN 绑定前先在事务内获取 advisory lock', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce(createEffectiveSuperAdmin())
      .mockResolvedValueOnce(
        createUserRecord({
          userRoles: [
            {
              role: createRole({
                id: 2,
                code: 'ADMIN',
                isSystem: false,
              }),
            },
          ],
        }),
      );
    prisma.role.findMany.mockResolvedValue([
      createRole({ id: 2, code: 'ADMIN', isSystem: false }),
    ]);
    prisma.role.findUnique.mockResolvedValue(
      createRole({ id: 1, code: 'SUPER_ADMIN', isActive: true }),
    );
    prisma.user.count.mockResolvedValue(2);
    prisma.userRole.deleteMany.mockResolvedValue({ count: 1 });
    prisma.userRole.createMany.mockResolvedValue({ count: 1 });
    prisma.auditLog.create.mockResolvedValue({});

    await service.assignRoles('target-user', { roleIds: [2] }, createActor());

    expect(getRawSqlText(prisma.$queryRaw.mock.calls[0]?.[0])).toContain(
      'pg_advisory_xact_lock',
    );
    expect(prisma.$queryRaw.mock.invocationCallOrder[0]).toBeLessThan(
      prisma.user.count.mock.invocationCallOrder[0],
    );
    expect(prisma.user.count.mock.invocationCallOrder[0]).toBeLessThan(
      prisma.userRole.deleteMany.mock.invocationCallOrder[0],
    );
  });

  it('重置密码递增 tokenVersion 且响应不返回 hash', async () => {
    prisma.user.findUnique.mockResolvedValue(createUserRecord());
    prisma.user.update.mockResolvedValue(createUserRecord({ tokenVersion: 9 }));
    prisma.auditLog.create.mockResolvedValue({});

    const result = await service.resetPassword(
      'target-user',
      { password: 'Next#123456' },
      createActor(),
    );

    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'target-user' },
      data: {
        passwordHash: expect.any(String),
        tokenVersion: { increment: 1 },
      },
      include: expect.any(Object),
    });
    const updateArg = prisma.user.update.mock.calls[0][0] as {
      data: { passwordHash: string };
    };
    await expect(
      argon2.verify(updateArg.data.passwordHash, 'Next#123456'),
    ).resolves.toBe(true);
    expect(JSON.stringify(result)).not.toContain('passwordHash');
    expect(JSON.stringify(result)).not.toContain('hash');
  });
});

function createPrismaMock() {
  return {
    $transaction: jest.fn(),
    $queryRaw: jest.fn().mockResolvedValue([]),
    user: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    role: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    userRole: {
      deleteMany: jest.fn(),
      createMany: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
  };
}

function getRawSqlText(rawSql: unknown): string {
  if (Array.isArray(rawSql)) {
    return rawSql.join('?');
  }

  return String(rawSql);
}

function createActor() {
  return {
    id: 'actor-user',
    username: 'actor',
    status: 'ACTIVE',
    tokenVersion: 0,
  };
}

function createUserRecord(overrides: Record<string, unknown> = {}) {
  return {
    id: 'target-user',
    username: 'target',
    status: UserStatus.ACTIVE,
    tokenVersion: 3,
    profile: {
      displayName: '目标用户',
      phone: null,
      email: null,
      avatarUrl: null,
      departmentName: null,
      postName: null,
    },
    userRoles: [],
    ...overrides,
  };
}

function createEffectiveSuperAdmin() {
  return createUserRecord({
    userRoles: [
      {
        role: createRole({
          id: 1,
          code: 'SUPER_ADMIN',
          isActive: true,
        }),
      },
    ],
  });
}

function createRole(overrides: Record<string, unknown> = {}) {
  return {
    id: 1,
    code: 'SUPER_ADMIN',
    name: '超级管理员',
    description: '系统维护者',
    isSystem: true,
    isActive: true,
    ...overrides,
  };
}
