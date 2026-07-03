import { PrismaService } from '../../database/prisma.service';
import { MenusService } from './menus.service';

describe('MenusService', () => {
  let prisma: {
    user: {
      findUnique: jest.Mock;
    };
  };
  let service: MenusService;

  beforeEach(() => {
    prisma = {
      user: {
        findUnique: jest.fn(),
      },
    };
    service = new MenusService(prisma as unknown as PrismaService);
  });

  it('拥有 menu:settings 时返回 /settings 菜单', async () => {
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        userRoles: [
          createUserRole({
            role: createRole({
              rolePermissions: [
                createRolePermission({
                  permission: createPermission({ code: 'menu:settings' }),
                }),
              ],
            }),
          }),
        ],
      }),
    );

    const menus = await service.getMyMenus(createCurrentUser());

    expect(menus).toEqual([
      {
        key: 'system-settings',
        title: '系统设置',
        route: '/settings',
        icon: 'Settings',
        permissionCode: 'menu:settings',
        sortOrder: 30,
        children: [],
      },
    ]);
  });

  it('没有 menu 权限时不返回菜单', async () => {
    prisma.user.findUnique.mockResolvedValue(
      createUserRecord({
        userRoles: [
          createUserRole({
            role: createRole({
              rolePermissions: [
                createRolePermission({
                  permission: createPermission({ code: 'api:menus:me' }),
                }),
              ],
            }),
          }),
        ],
      }),
    );

    await expect(service.getMyMenus(createCurrentUser())).resolves.toEqual([]);
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
    status: 'ACTIVE',
    userRoles: [],
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
    id: 1,
    code: 'menu:dashboard',
    type: 'MENU',
    isActive: true,
    sortOrder: 10,
    ...overrides,
  };
}
