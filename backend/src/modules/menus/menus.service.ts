import { HttpStatus, Injectable } from '@nestjs/common';
import { UserStatus } from '@prisma/client';

import { PrismaService } from '../../database/prisma.service';
import { throwAuthException } from '../auth/auth.errors';
import type { AuthMenu } from '../auth/models/auth-session.model';
import type { CurrentUserPayload } from '../auth/models/current-user.model';
import { MENU_DEFINITIONS } from './menu-definitions';

const MENU_USER_SELECT = {
  id: true,
  status: true,
  userRoles: {
    select: {
      role: {
        select: {
          id: true,
          isActive: true,
          rolePermissions: {
            select: {
              permission: {
                select: {
                  code: true,
                  isActive: true,
                },
              },
            },
          },
        },
      },
    },
  },
} as const;

@Injectable()
export class MenusService {
  constructor(private readonly prisma: PrismaService) {}

  async getMyMenus(currentUser: CurrentUserPayload): Promise<AuthMenu[]> {
    const user = await this.prisma.user.findUnique({
      where: { id: currentUser.id },
      select: MENU_USER_SELECT,
    });

    if (!user) {
      throwAuthException(
        'UNAUTHORIZED',
        'User not found.',
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

    const activeRoles = user.userRoles
      .map((userRole) => userRole.role)
      .filter((role) => role.isActive);

    if (activeRoles.length === 0) {
      throwAuthException(
        'NO_ACTIVE_ROLE',
        'User has no active role.',
        HttpStatus.FORBIDDEN,
      );
    }

    const menuPermissionCodes = new Set<string>();

    for (const role of activeRoles) {
      for (const rolePermission of role.rolePermissions) {
        const permission = rolePermission.permission;

        if (permission.isActive && permission.code.startsWith('menu:')) {
          menuPermissionCodes.add(permission.code);
        }
      }
    }

    return MENU_DEFINITIONS.filter((menu) =>
      menuPermissionCodes.has(menu.permissionCode),
    ).map((menu) => ({
      ...menu,
      children: [],
    }));
  }
}
