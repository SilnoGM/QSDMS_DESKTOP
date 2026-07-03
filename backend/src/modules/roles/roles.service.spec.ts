import { PrismaService } from '../../database/prisma.service';
import { RolesService } from './roles.service';

describe('RolesService', () => {
  let prisma: {
    $transaction: jest.Mock;
    role: Record<string, jest.Mock>;
    permission: Record<string, jest.Mock>;
    rolePermission: Record<string, jest.Mock>;
    auditLog: Record<string, jest.Mock>;
  };
  let service: RolesService;

  beforeEach(() => {
    prisma = createPrismaMock();
    prisma.$transaction.mockImplementation((callback) => callback(prisma));
    service = new RolesService(prisma as unknown as PrismaService);
  });

  it('禁止禁用 SUPER_ADMIN 角色', async () => {
    prisma.role.findUnique.mockResolvedValue(
      createRole({ code: 'SUPER_ADMIN' }),
    );

    await expect(
      service.update(1, { isActive: false }, createActor()),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
    expect(prisma.role.update).not.toHaveBeenCalled();
  });

  it('禁止通过 API 修改 SUPER_ADMIN 角色权限', async () => {
    prisma.role.findUnique.mockResolvedValue(
      createRole({ code: 'SUPER_ADMIN' }),
    );

    await expect(
      service.assignPermissions(1, { permissionIds: [1] }, createActor()),
    ).rejects.toMatchObject({
      response: {
        code: 'FORBIDDEN',
        data: null,
      },
      status: 403,
    });
    expect(prisma.rolePermission.deleteMany).not.toHaveBeenCalled();
  });

  it('角色权限分配使用事务替换集合并写审计', async () => {
    prisma.role.findUnique.mockResolvedValue(createRole({ code: 'ADMIN' }));
    prisma.permission.findMany.mockResolvedValue([
      createPermission({ id: 10 }),
      createPermission({ id: 11 }),
    ]);
    prisma.rolePermission.deleteMany.mockResolvedValue({ count: 1 });
    prisma.rolePermission.createMany.mockResolvedValue({ count: 2 });
    prisma.auditLog.create.mockResolvedValue({});

    await service.assignPermissions(
      2,
      { permissionIds: [10, 11] },
      createActor(),
    );

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.rolePermission.deleteMany).toHaveBeenCalledWith({
      where: { roleId: 2 },
    });
    expect(prisma.rolePermission.createMany).toHaveBeenCalledWith({
      data: [
        { roleId: 2, permissionId: 10, assignedBy: 'actor-user' },
        { roleId: 2, permissionId: 11, assignedBy: 'actor-user' },
      ],
      skipDuplicates: true,
    });
    expect(prisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        actorUserId: 'actor-user',
        action: 'ROLE_PERMISSIONS_ASSIGNED',
        resourceType: 'Role',
        resourceId: '2',
        metadata: {
          permissionIds: [10, 11],
          changedFields: ['permissions'],
        },
      }),
    });
  });
});

function createPrismaMock() {
  return {
    $transaction: jest.fn(),
    role: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    permission: {
      findMany: jest.fn(),
    },
    rolePermission: {
      deleteMany: jest.fn(),
      createMany: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
  };
}

function createActor() {
  return {
    id: 'actor-user',
    username: 'actor',
    status: 'ACTIVE',
    tokenVersion: 0,
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

function createPermission(overrides: Record<string, unknown> = {}) {
  return {
    id: 10,
    code: 'api:users:list',
    name: '用户列表接口',
    type: 'API',
    module: 'system',
    description: null,
    sortOrder: 10,
    isSystem: true,
    isActive: true,
    ...overrides,
  };
}
