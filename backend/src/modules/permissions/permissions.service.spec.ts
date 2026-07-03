import { PrismaService } from '../../database/prisma.service';
import { PermissionsService } from './permissions.service';

describe('PermissionsService', () => {
  it('tree 按 module/type 分组并保持稳定排序', async () => {
    const prisma = {
      permission: {
        findMany: jest.fn().mockResolvedValue([
          createPermission({ code: 'api:users:list', type: 'API' }),
          createPermission({
            id: 2,
            code: 'menu:settings',
            type: 'MENU',
            sortOrder: 1,
          }),
        ]),
      },
    };
    const service = new PermissionsService(prisma as unknown as PrismaService);

    await expect(service.tree()).resolves.toEqual([
      {
        module: 'system',
        groups: [
          {
            type: 'MENU',
            permissions: [
              expect.objectContaining({
                code: 'menu:settings',
              }),
            ],
          },
          {
            type: 'API',
            permissions: [
              expect.objectContaining({
                code: 'api:users:list',
              }),
            ],
          },
        ],
      },
    ]);
  });
});

function createPermission(overrides: Record<string, unknown> = {}) {
  return {
    id: 1,
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
