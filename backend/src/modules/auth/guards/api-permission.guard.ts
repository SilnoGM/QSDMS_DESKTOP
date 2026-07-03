import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PermissionType, UserStatus } from '@prisma/client';

import { PrismaService } from '../../../database/prisma.service';
import { throwAuthException } from '../auth.errors';
import { API_PERMISSION_KEY } from '../decorators/api-permission.decorator';
import { PUBLIC_ROUTE_KEY } from '../decorators/public.decorator';
import { AuthenticatedRequest } from '../models/authenticated-request.model';

const USER_PERMISSION_SELECT = {
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
                  type: true,
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
export class ApiPermissionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublicRoute = this.reflector.getAllAndOverride<boolean>(
      PUBLIC_ROUTE_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (isPublicRoute) {
      return true;
    }

    const requiredPermissionCodes = this.reflector.getAllAndOverride<
      readonly string[] | undefined
    >(API_PERMISSION_KEY, [context.getHandler(), context.getClass()]);

    if (!requiredPermissionCodes || requiredPermissionCodes.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const currentUser = request.user;

    if (!currentUser) {
      throwAuthException(
        'UNAUTHORIZED',
        'Authenticated user is required.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { id: currentUser.id },
      select: USER_PERMISSION_SELECT,
    });

    if (!user) {
      throwAuthException(
        'UNAUTHORIZED',
        'Authenticated user is required.',
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

    const grantedPermissionCodes = new Set<string>();

    for (const role of activeRoles) {
      for (const rolePermission of role.rolePermissions) {
        const permission = rolePermission.permission;

        // 首版授权不做缓存，每次请求都从数据库读取“启用角色 + 启用 API 权限”。
        // 禁用角色、禁用权限、非 API 类型权限都不能参与后端接口授权。
        if (permission.isActive && permission.type === PermissionType.API) {
          grantedPermissionCodes.add(permission.code);
        }
      }
    }

    const hasAllRequiredPermissions = requiredPermissionCodes.every(
      (permissionCode) => grantedPermissionCodes.has(permissionCode),
    );

    if (!hasAllRequiredPermissions) {
      throwAuthException(
        'FORBIDDEN',
        'Missing required API permission.',
        HttpStatus.FORBIDDEN,
      );
    }

    return true;
  }
}
