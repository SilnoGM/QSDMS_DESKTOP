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

  it('非 SUPER_ADMIN 创建用户时不能授予 SUPER_ADMIN 角色', async () => {
    prisma.role.findMany.mockResolvedValue([createRole()]);
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        id: 'actor-user',
        username: 'actor',
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
    prisma.user.create.mockResolvedValue(
      createEffectiveSuperAdmin({
        id: 'new-user',
        username: 'new-user',
        profile: {
          displayName: '新用户',
          phone: null,
          email: null,
          avatarUrl: null,
          departmentName: null,
          postName: null,
        },
      }),
    );
    prisma.auditLog.create.mockResolvedValue({});

    await expect(
      service.create(createCreateUserDto({ roleIds: [1] }), createActor()),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
    expect(prisma.user.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'actor-user' } }),
    );
    expect(prisma.user.create).not.toHaveBeenCalled();
    expect(prisma.auditLog.create).not.toHaveBeenCalled();
  });

  it('有效 SUPER_ADMIN 创建用户时可以授予 SUPER_ADMIN 角色', async () => {
    prisma.role.findMany.mockResolvedValue([createRole()]);
    prisma.user.findUnique.mockResolvedValue(
      createEffectiveSuperAdmin({
        id: 'actor-user',
        username: 'actor',
      }),
    );
    prisma.user.create.mockResolvedValue(
      createEffectiveSuperAdmin({
        id: 'new-user',
        username: 'new-user',
        profile: {
          displayName: '新用户',
          phone: null,
          email: null,
          avatarUrl: null,
          departmentName: null,
          postName: null,
        },
      }),
    );
    prisma.auditLog.create.mockResolvedValue({});

    await expect(
      service.create(createCreateUserDto({ roleIds: [1] }), createActor()),
    ).resolves.toMatchObject({
      id: 'new-user',
      roles: [expect.objectContaining({ code: 'SUPER_ADMIN' })],
    });

    expect(prisma.user.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'actor-user' } }),
    );
    expect(prisma.user.findUnique.mock.invocationCallOrder[0]).toBeLessThan(
      prisma.user.create.mock.invocationCallOrder[0],
    );
    expect(prisma.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userRoles: {
            create: [
              {
                roleId: 1,
                assignedBy: 'actor-user',
              },
            ],
          },
        }),
      }),
    );
    expect(prisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        actorUserId: 'actor-user',
        metadata: {
          targetUsername: 'new-user',
          roleIds: [1],
          changedFields: ['username', 'profile', 'roles'],
        },
      }),
    });
    expect(JSON.stringify(prisma.auditLog.create.mock.calls[0][0].data.metadata))
      .not.toContain('actor');
  });

  it('创建普通角色用户时不要求操作者是 SUPER_ADMIN', async () => {
    prisma.role.findMany.mockResolvedValue([
      createRole({ id: 2, code: 'ADMIN', isSystem: false }),
    ]);
    prisma.user.create.mockResolvedValue(
      createUserRecord({
        id: 'new-user',
        username: 'new-user',
        profile: {
          displayName: '新用户',
          phone: null,
          email: null,
          avatarUrl: null,
          departmentName: null,
          postName: null,
        },
        userRoles: [
          {
            role: createRole({ id: 2, code: 'ADMIN', isSystem: false }),
          },
        ],
      }),
    );
    prisma.auditLog.create.mockResolvedValue({});

    await expect(
      service.create(createCreateUserDto({ roleIds: [2] }), createActor()),
    ).resolves.toMatchObject({
      id: 'new-user',
      roles: [expect.objectContaining({ code: 'ADMIN' })],
    });

    expect(prisma.user.findUnique).not.toHaveBeenCalled();
    expect(prisma.user.create).toHaveBeenCalled();
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

  it('非 SUPER_ADMIN 不能分配 SUPER_ADMIN 角色', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce(createUserRecord())
      .mockResolvedValueOnce(
        createUserRecord({
          id: 'actor-user',
          username: 'actor',
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
    prisma.role.findMany.mockResolvedValue([createRole()]);

    await expect(
      service.assignRoles('target-user', { roleIds: [1] }, createActor()),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
    expect(prisma.user.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'actor-user' } }),
    );
    expect(prisma.userRole.deleteMany).not.toHaveBeenCalled();
    expect(prisma.auditLog.create).not.toHaveBeenCalled();
  });

  it('有效 SUPER_ADMIN 可以分配 SUPER_ADMIN 角色且审计 metadata 不写入操作者详情', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce(createUserRecord())
      .mockResolvedValueOnce(
        createEffectiveSuperAdmin({
          id: 'actor-user',
          username: 'actor',
        }),
      )
      .mockResolvedValueOnce(
        createUserRecord({
          userRoles: [
            {
              role: createRole(),
            },
          ],
        }),
      );
    prisma.role.findMany.mockResolvedValue([createRole()]);
    prisma.userRole.deleteMany.mockResolvedValue({ count: 0 });
    prisma.userRole.createMany.mockResolvedValue({ count: 1 });
    prisma.auditLog.create.mockResolvedValue({});

    await expect(
      service.assignRoles('target-user', { roleIds: [1] }, createActor()),
    ).resolves.toMatchObject({
      id: 'target-user',
      roles: [expect.objectContaining({ code: 'SUPER_ADMIN' })],
    });

    expect(prisma.user.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'actor-user' } }),
    );
    expect(prisma.userRole.createMany).toHaveBeenCalledWith({
      data: [
        {
          userId: 'target-user',
          roleId: 1,
          assignedBy: 'actor-user',
        },
      ],
      skipDuplicates: true,
    });
    expect(prisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        actorUserId: 'actor-user',
        metadata: {
          targetUsername: 'target',
          roleIds: [1],
          changedFields: ['roles'],
        },
      }),
    });
    expect(JSON.stringify(prisma.auditLog.create.mock.calls[0][0].data.metadata))
      .not.toContain('actor');
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

function createCreateUserDto(overrides: Record<string, unknown> = {}) {
  return {
    username: 'new-user',
    password: 'Init#123456',
    displayName: '新用户',
    roleIds: [2],
    ...overrides,
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

function createEffectiveSuperAdmin(overrides: Record<string, unknown> = {}) {
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
    ...overrides,
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
