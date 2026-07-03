import { HttpStatus, Injectable } from '@nestjs/common';
import { Permission, Prisma } from '@prisma/client';

import { PrismaService } from '../../database/prisma.service';
import { throwAuthException } from '../auth/auth.errors';
import type { CurrentUserPayload } from '../auth/models/current-user.model';
import { SYSTEM_ROLE_CODES } from '../authz/permission-seed-data';
import { AssignRolePermissionsDto } from './dto/assign-role-permissions.dto';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';

const ROLE_INCLUDE = {
  rolePermissions: {
    include: {
      permission: true,
    },
  },
} as const;

type RoleRecord = Prisma.RoleGetPayload<{ include: typeof ROLE_INCLUDE }>;

export type RolePermissionResponse = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly type: string;
  readonly module: string;
  readonly description: string | null;
  readonly sortOrder: number;
  readonly isSystem: boolean;
  readonly isActive: boolean;
};

export type RoleResponse = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly description: string | null;
  readonly isSystem: boolean;
  readonly isActive: boolean;
  readonly permissions: RolePermissionResponse[];
};

@Injectable()
export class RolesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(): Promise<RoleResponse[]> {
    const roles = await this.prisma.role.findMany({
      include: ROLE_INCLUDE,
      orderBy: [{ id: 'asc' }],
    });

    return roles.map((role) => this.toResponse(role));
  }

  async create(
    dto: CreateRoleDto,
    actor: CurrentUserPayload,
  ): Promise<RoleResponse> {
    const role = await this.prisma.$transaction(async (tx) => {
      const created = await tx.role.create({
        data: {
          code: dto.code,
          name: dto.name,
          description: dto.description,
          isSystem: false,
          isActive: dto.isActive ?? true,
        },
        include: ROLE_INCLUDE,
      });

      await this.writeAudit(tx, actor, {
        action: 'ROLE_CREATED',
        resourceId: String(created.id),
        metadata: {
          changedFields: ['code', 'name', 'description', 'isActive'],
        },
      });

      return created;
    });

    return this.toResponse(role);
  }

  async update(
    id: number,
    dto: UpdateRoleDto,
    actor: CurrentUserPayload,
  ): Promise<RoleResponse> {
    const role = await this.findRoleOrThrow(this.prisma, id);

    if (dto.isActive === false) {
      this.assertRoleCanBeDisabled(role);
    }

    const data: Prisma.RoleUpdateInput = {};
    const changedFields: string[] = [];

    if (dto.name !== undefined) {
      data.name = dto.name;
      changedFields.push('name');
    }

    if (dto.description !== undefined) {
      data.description = dto.description;
      changedFields.push('description');
    }

    if (dto.isActive !== undefined) {
      data.isActive = dto.isActive;
      changedFields.push('isActive');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const nextRole = await tx.role.update({
        where: { id },
        data,
        include: ROLE_INCLUDE,
      });

      await this.writeAudit(tx, actor, {
        action: 'ROLE_UPDATED',
        resourceId: String(id),
        metadata: { changedFields },
      });

      return nextRole;
    });

    return this.toResponse(updated);
  }

  async assignPermissions(
    roleId: number,
    dto: AssignRolePermissionsDto,
    actor: CurrentUserPayload,
  ): Promise<RoleResponse> {
    const permissionIds = normalizeIds(dto.permissionIds);

    const role = await this.prisma.$transaction(async (tx) => {
      const targetRole = await this.findRoleOrThrow(tx, roleId);

      // SUPER_ADMIN 的权限首版只由 seed 管理，禁止 API 修改，避免误删最后救援权限。
      if (targetRole.code === SYSTEM_ROLE_CODES.SUPER_ADMIN) {
        throwAuthException(
          'FORBIDDEN',
          'SUPER_ADMIN role permissions cannot be modified by API.',
          HttpStatus.FORBIDDEN,
        );
      }

      const permissions = await this.findActivePermissionsOrThrow(
        tx,
        permissionIds,
      );

      await tx.rolePermission.deleteMany({
        where: { roleId },
      });

      if (permissionIds.length > 0) {
        await tx.rolePermission.createMany({
          data: permissions.map((permission) => ({
            roleId,
            permissionId: permission.id,
            assignedBy: actor.id,
          })),
          skipDuplicates: true,
        });
      }

      await this.writeAudit(tx, actor, {
        action: 'ROLE_PERMISSIONS_ASSIGNED',
        resourceId: String(roleId),
        metadata: {
          permissionIds,
          changedFields: ['permissions'],
        },
      });

      return this.findRoleOrThrow(tx, roleId);
    });

    return this.toResponse(role);
  }

  private async findRoleOrThrow(
    client: Prisma.TransactionClient | PrismaService,
    id: number,
  ): Promise<RoleRecord> {
    const role = await client.role.findUnique({
      where: { id },
      include: ROLE_INCLUDE,
    });

    if (!role) {
      throwAuthException('NOT_FOUND', 'Role not found.', HttpStatus.NOT_FOUND);
    }

    return role;
  }

  private assertRoleCanBeDisabled(role: RoleRecord): void {
    if (role.code === SYSTEM_ROLE_CODES.SUPER_ADMIN || role.isSystem) {
      throwAuthException(
        'FORBIDDEN',
        'System role cannot be disabled.',
        HttpStatus.FORBIDDEN,
      );
    }
  }

  private async findActivePermissionsOrThrow(
    client: Prisma.TransactionClient,
    permissionIds: readonly number[],
  ): Promise<Permission[]> {
    if (permissionIds.length === 0) {
      return [];
    }

    const permissions = await client.permission.findMany({
      where: {
        id: { in: [...permissionIds] },
        isActive: true,
      },
      orderBy: [{ id: 'asc' }],
    });

    if (permissions.length !== permissionIds.length) {
      throwAuthException(
        'BAD_REQUEST',
        'All permissions must exist and be active.',
        HttpStatus.BAD_REQUEST,
      );
    }

    return [...permissions].sort(
      (left, right) =>
        permissionIds.indexOf(left.id) - permissionIds.indexOf(right.id),
    );
  }

  private async writeAudit(
    client: Prisma.TransactionClient,
    actor: CurrentUserPayload,
    input: {
      readonly action: string;
      readonly resourceId: string;
      readonly metadata: Prisma.InputJsonObject;
    },
  ): Promise<void> {
    // 审计 metadata 只写白名单摘要，禁止保存请求体、密码、hash、token 或 header。
    await client.auditLog.create({
      data: {
        actorUserId: actor.id,
        action: input.action,
        resourceType: 'Role',
        resourceId: input.resourceId,
        metadata: input.metadata,
      },
    });
  }

  private toResponse(role: RoleRecord): RoleResponse {
    return {
      id: role.id,
      code: role.code,
      name: role.name,
      description: role.description,
      isSystem: role.isSystem,
      isActive: role.isActive,
      permissions: role.rolePermissions
        .map((rolePermission) => rolePermission.permission)
        .sort(
          (left, right) =>
            left.sortOrder - right.sortOrder ||
            left.code.localeCompare(right.code),
        )
        .map((permission) => ({
          id: permission.id,
          code: permission.code,
          name: permission.name,
          type: permission.type,
          module: permission.module,
          description: permission.description,
          sortOrder: permission.sortOrder,
          isSystem: permission.isSystem,
          isActive: permission.isActive,
        })),
    };
  }
}

function normalizeIds(ids: readonly number[]): number[] {
  return [...new Set(ids)];
}
