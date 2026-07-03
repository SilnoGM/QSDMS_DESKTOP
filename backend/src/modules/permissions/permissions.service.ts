import { Injectable } from '@nestjs/common';
import { Permission, PermissionType } from '@prisma/client';

import { PrismaService } from '../../database/prisma.service';

export type PermissionResponse = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly type: PermissionType;
  readonly module: string;
  readonly description: string | null;
  readonly sortOrder: number;
  readonly isSystem: boolean;
  readonly isActive: boolean;
};

export type PermissionTreeGroup = {
  readonly type: PermissionType;
  readonly permissions: PermissionResponse[];
};

export type PermissionTreeNode = {
  readonly module: string;
  readonly groups: PermissionTreeGroup[];
};

const PERMISSION_TYPE_ORDER: readonly PermissionType[] = [
  PermissionType.MENU,
  PermissionType.ACTION,
  PermissionType.API,
];

@Injectable()
export class PermissionsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(): Promise<PermissionResponse[]> {
    const permissions = await this.findOrderedPermissions();

    return permissions.map((permission) => this.toResponse(permission));
  }

  async tree(): Promise<PermissionTreeNode[]> {
    const permissions = await this.findOrderedPermissions();
    const permissionsByModule = new Map<
      string,
      Map<PermissionType, PermissionResponse[]>
    >();

    for (const permission of permissions) {
      const moduleGroups =
        permissionsByModule.get(permission.module) ??
        new Map<PermissionType, PermissionResponse[]>();
      const typePermissions = moduleGroups.get(permission.type) ?? [];

      typePermissions.push(this.toResponse(permission));
      moduleGroups.set(permission.type, typePermissions);
      permissionsByModule.set(permission.module, moduleGroups);
    }

    return [...permissionsByModule.entries()].map(([module, groups]) => ({
      module,
      groups: [...groups.entries()]
        .sort(
          ([leftType], [rightType]) =>
            PERMISSION_TYPE_ORDER.indexOf(leftType) -
            PERMISSION_TYPE_ORDER.indexOf(rightType),
        )
        .map(([type, groupedPermissions]) => ({
          type,
          permissions: groupedPermissions,
        })),
    }));
  }

  private findOrderedPermissions(): Promise<Permission[]> {
    return this.prisma.permission.findMany({
      orderBy: [
        { module: 'asc' },
        { type: 'asc' },
        { sortOrder: 'asc' },
        { code: 'asc' },
      ],
    });
  }

  private toResponse(permission: Permission): PermissionResponse {
    return {
      id: permission.id,
      code: permission.code,
      name: permission.name,
      type: permission.type,
      module: permission.module,
      description: permission.description,
      sortOrder: permission.sortOrder,
      isSystem: permission.isSystem,
      isActive: permission.isActive,
    };
  }
}
