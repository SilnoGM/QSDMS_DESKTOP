import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma, Role, UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';

import { PrismaService } from '../../database/prisma.service';
import { throwAuthException } from '../auth/auth.errors';
import type { CurrentUserPayload } from '../auth/models/current-user.model';
import { SYSTEM_ROLE_CODES } from '../authz/permission-seed-data';
import { AssignUserRolesDto } from './dto/assign-user-roles.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { ResetUserPasswordDto } from './dto/reset-user-password.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpdateUserDto } from './dto/update-user.dto';

const USER_INCLUDE = {
  profile: true,
  userRoles: {
    include: {
      role: true,
    },
  },
} as const;

const SUPER_ADMIN_GUARD_LOCK_NAMESPACE = 20260703;
const SUPER_ADMIN_GUARD_LOCK_ID = 1001;

type UserRecord = Prisma.UserGetPayload<{ include: typeof USER_INCLUDE }>;

export type UserProfileResponse = {
  readonly displayName: string;
  readonly phone: string | null;
  readonly email: string | null;
  readonly avatarUrl: string | null;
  readonly departmentName: string | null;
  readonly postName: string | null;
};

export type UserRoleResponse = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly description: string | null;
  readonly isSystem: boolean;
  readonly isActive: boolean;
};

export type UserResponse = {
  readonly id: string;
  readonly username: string;
  readonly status: UserStatus;
  readonly profile: UserProfileResponse | null;
  readonly roles: UserRoleResponse[];
};

export type ResetPasswordResponse = {
  readonly success: true;
};

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async list(): Promise<UserResponse[]> {
    const users = await this.prisma.user.findMany({
      include: USER_INCLUDE,
      orderBy: [{ createdAt: 'desc' }],
    });

    return users.map((user) => this.toResponse(user));
  }

  async detail(id: string): Promise<UserResponse> {
    return this.toResponse(await this.findUserOrThrow(this.prisma, id));
  }

  async create(
    dto: CreateUserDto,
    actor: CurrentUserPayload,
  ): Promise<UserResponse> {
    const roleIds = normalizeIds(dto.roleIds);
    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
    });

    const user = await this.prisma.$transaction(async (tx) => {
      const roles = await this.findActiveRolesOrThrow(tx, roleIds);
      // 创建用户时直接授予 SUPER_ADMIN 同样属于二阶提权，必须在写入
      // userRoles 前确认当前操作者仍是有效超级管理员。
      await this.assertCanGrantSuperAdminRole(tx, actor, roles);
      const created = await tx.user.create({
        data: {
          username: dto.username,
          passwordHash,
          profile: {
            create: {
              displayName: dto.displayName,
              phone: dto.phone,
              email: dto.email,
              avatarUrl: dto.avatarUrl,
              departmentName: dto.departmentName,
              postName: dto.postName,
            },
          },
          userRoles: {
            create: roles.map((role) => ({
              roleId: role.id,
              assignedBy: actor.id,
            })),
          },
        },
        include: USER_INCLUDE,
      });

      await this.writeAudit(tx, actor, {
        action: 'USER_CREATED',
        resourceId: created.id,
        metadata: {
          targetUsername: created.username,
          roleIds,
          changedFields: ['username', 'profile', 'roles'],
        },
      });

      return created;
    });

    return this.toResponse(user);
  }

  async update(
    id: string,
    dto: UpdateUserDto,
    actor: CurrentUserPayload,
  ): Promise<UserResponse> {
    const user = await this.prisma.$transaction(async (tx) => {
      const current = await this.findUserOrThrow(tx, id);
      const changedFields = this.getChangedUserFields(dto);
      const data = this.buildUpdateData(current, dto);
      const updated = await tx.user.update({
        where: { id },
        data,
        include: USER_INCLUDE,
      });

      await this.writeAudit(tx, actor, {
        action: 'USER_UPDATED',
        resourceId: id,
        metadata: {
          targetUsername: current.username,
          changedFields,
        },
      });

      return updated;
    });

    return this.toResponse(user);
  }

  async updateStatus(
    id: string,
    dto: UpdateUserStatusDto,
    actor: CurrentUserPayload,
  ): Promise<UserResponse> {
    const user = await this.prisma.$transaction(async (tx) => {
      if (dto.status !== UserStatus.ACTIVE) {
        await this.acquireSuperAdminGuardLock(tx);
      }

      const current = await this.findUserOrThrow(tx, id);

      if (dto.status !== UserStatus.ACTIVE) {
        await this.assertCanDisableOrLockUser(tx, current);
      }

      const updated = await tx.user.update({
        where: { id },
        data:
          dto.status === UserStatus.ACTIVE
            ? { status: dto.status }
            : {
                status: dto.status,
                tokenVersion: { increment: 1 },
              },
        include: USER_INCLUDE,
      });

      await this.writeAudit(tx, actor, {
        action: 'USER_STATUS_UPDATED',
        resourceId: id,
        metadata: {
          targetUsername: current.username,
          oldStatus: current.status,
          newStatus: dto.status,
          changedFields: ['status'],
        },
      });

      return updated;
    });

    return this.toResponse(user);
  }

  async resetPassword(
    id: string,
    dto: ResetUserPasswordDto,
    actor: CurrentUserPayload,
  ): Promise<ResetPasswordResponse> {
    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
    });

    await this.prisma.$transaction(async (tx) => {
      const current = await this.findUserOrThrow(tx, id);

      await tx.user.update({
        where: { id },
        data: {
          passwordHash,
          tokenVersion: { increment: 1 },
        },
        include: USER_INCLUDE,
      });

      await this.writeAudit(tx, actor, {
        action: 'USER_PASSWORD_RESET',
        resourceId: id,
        metadata: {
          targetUsername: current.username,
          changedFields: ['password'],
        },
      });
    });

    return { success: true };
  }

  async assignRoles(
    id: string,
    dto: AssignUserRolesDto,
    actor: CurrentUserPayload,
  ): Promise<UserResponse> {
    const roleIds = normalizeIds(dto.roleIds);

    const user = await this.prisma.$transaction(async (tx) => {
      await this.acquireSuperAdminGuardLock(tx);

      const current = await this.findUserOrThrow(tx, id);
      const roles = await this.findActiveRolesOrThrow(tx, roleIds);

      await this.assertCanGrantSuperAdminRole(tx, actor, roles);
      await this.assertCanReplaceRoles(tx, current, roleIds);

      await tx.userRole.deleteMany({
        where: { userId: id },
      });

      if (roles.length > 0) {
        await tx.userRole.createMany({
          data: roles.map((role) => ({
            userId: id,
            roleId: role.id,
            assignedBy: actor.id,
          })),
          skipDuplicates: true,
        });
      }

      await this.writeAudit(tx, actor, {
        action: 'USER_ROLES_ASSIGNED',
        resourceId: id,
        metadata: {
          targetUsername: current.username,
          roleIds,
          changedFields: ['roles'],
        },
      });

      return this.findUserOrThrow(tx, id);
    });

    return this.toResponse(user);
  }

  private async acquireSuperAdminGuardLock(
    client: Prisma.TransactionClient,
  ): Promise<void> {
    // PostgreSQL transaction-scoped advisory lock 会在当前事务结束时自动释放。
    // 这里串行化所有可能削减有效 SUPER_ADMIN 数量的操作，避免两个并发事务
    // 分别看到 count=2 后同时禁用/移除不同超级管理员，最终留下 0 个救援账号。
    await client.$queryRaw`
      SELECT pg_advisory_xact_lock(${SUPER_ADMIN_GUARD_LOCK_NAMESPACE}, ${SUPER_ADMIN_GUARD_LOCK_ID})
    `;
  }

  private async findUserOrThrow(
    client: Prisma.TransactionClient | PrismaService,
    id: string,
  ): Promise<UserRecord> {
    const user = await client.user.findUnique({
      where: { id },
      include: USER_INCLUDE,
    });

    if (!user) {
      throwAuthException('NOT_FOUND', 'User not found.', HttpStatus.NOT_FOUND);
    }

    return user;
  }

  private async findActiveRolesOrThrow(
    client: Prisma.TransactionClient,
    roleIds: readonly number[],
  ): Promise<Role[]> {
    if (roleIds.length === 0) {
      return [];
    }

    const roles = await client.role.findMany({
      where: {
        id: { in: [...roleIds] },
        isActive: true,
      },
      orderBy: [{ id: 'asc' }],
    });

    if (roles.length !== roleIds.length) {
      throwAuthException(
        'BAD_REQUEST',
        'All roles must exist and be active.',
        HttpStatus.BAD_REQUEST,
      );
    }

    return [...roles].sort(
      (left, right) => roleIds.indexOf(left.id) - roleIds.indexOf(right.id),
    );
  }

  private async assertCanGrantSuperAdminRole(
    client: Prisma.TransactionClient,
    actor: CurrentUserPayload,
    roles: readonly Role[],
  ): Promise<void> {
    const grantsSuperAdminRole = roles.some(
      (role) => role.code === SYSTEM_ROLE_CODES.SUPER_ADMIN,
    );

    if (!grantsSuperAdminRole) {
      return;
    }

    const actorUser = await client.user.findUnique({
      where: { id: actor.id },
      include: USER_INCLUDE,
    });

    // 授予 SUPER_ADMIN 是二阶提权：即使调用者拥有 assign-roles API 权限，
    // 也必须在当前事务内确认其仍是 ACTIVE 且绑定启用 SUPER_ADMIN 角色。
    if (!actorUser || !this.isEffectiveSuperAdmin(actorUser)) {
      throwAuthException(
        'FORBIDDEN',
        'Only effective SUPER_ADMIN can assign SUPER_ADMIN role.',
        HttpStatus.FORBIDDEN,
      );
    }
  }

  private async assertCanDisableOrLockUser(
    client: Prisma.TransactionClient,
    user: UserRecord,
  ): Promise<void> {
    if (!this.isEffectiveSuperAdmin(user)) {
      return;
    }

    const effectiveSuperAdminCount =
      await this.countEffectiveSuperAdmins(client);

    // “最后有效超级管理员”是首版最重要的救援账号保护：ACTIVE 用户 + 启用的
    // SUPER_ADMIN 角色绑定同时存在时才算有效；只剩一个时禁止禁用或锁定。
    if (effectiveSuperAdminCount <= 1) {
      throwAuthException(
        'FORBIDDEN',
        'Cannot disable or lock the last effective SUPER_ADMIN user.',
        HttpStatus.FORBIDDEN,
      );
    }
  }

  private async assertCanReplaceRoles(
    client: Prisma.TransactionClient,
    user: UserRecord,
    nextRoleIds: readonly number[],
  ): Promise<void> {
    if (!this.isEffectiveSuperAdmin(user)) {
      return;
    }

    const superAdminRole = await client.role.findUnique({
      where: { code: SYSTEM_ROLE_CODES.SUPER_ADMIN },
      select: { id: true, isActive: true },
    });
    const keepsSuperAdminRole =
      superAdminRole != null &&
      superAdminRole.isActive &&
      nextRoleIds.includes(superAdminRole.id);

    if (keepsSuperAdminRole) {
      return;
    }

    const effectiveSuperAdminCount =
      await this.countEffectiveSuperAdmins(client);

    // 替换角色集合时，不能把最后一个有效超级管理员的 SUPER_ADMIN 绑定移除。
    if (effectiveSuperAdminCount <= 1) {
      throwAuthException(
        'FORBIDDEN',
        'Cannot remove SUPER_ADMIN role from the last effective SUPER_ADMIN user.',
        HttpStatus.FORBIDDEN,
      );
    }
  }

  private countEffectiveSuperAdmins(
    client: Prisma.TransactionClient,
  ): Promise<number> {
    return client.user.count({
      where: {
        status: UserStatus.ACTIVE,
        userRoles: {
          some: {
            role: {
              code: SYSTEM_ROLE_CODES.SUPER_ADMIN,
              isActive: true,
            },
          },
        },
      },
    });
  }

  private isEffectiveSuperAdmin(user: UserRecord): boolean {
    return (
      user.status === UserStatus.ACTIVE &&
      user.userRoles.some(
        (userRole) =>
          userRole.role.code === SYSTEM_ROLE_CODES.SUPER_ADMIN &&
          userRole.role.isActive,
      )
    );
  }

  private buildUpdateData(
    current: UserRecord,
    dto: UpdateUserDto,
  ): Prisma.UserUpdateInput {
    const data: Prisma.UserUpdateInput = {};

    if (dto.username !== undefined) {
      data.username = dto.username;
    }

    const profileData = pickDefined({
      displayName: dto.displayName,
      phone: dto.phone,
      email: dto.email,
      avatarUrl: dto.avatarUrl,
      departmentName: dto.departmentName,
      postName: dto.postName,
    });

    if (Object.keys(profileData).length > 0) {
      data.profile = {
        upsert: {
          create: {
            displayName:
              dto.displayName ??
              current.profile?.displayName ??
              current.username,
            phone: dto.phone,
            email: dto.email,
            avatarUrl: dto.avatarUrl,
            departmentName: dto.departmentName,
            postName: dto.postName,
          },
          update: profileData,
        },
      };
    }

    return data;
  }

  private getChangedUserFields(dto: UpdateUserDto): string[] {
    return Object.entries(dto)
      .filter(([, value]) => value !== undefined)
      .map(([key]) => key);
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
    // 审计只保存明确白名单字段，避免把密码、hash、token、请求头或完整 body 写入日志。
    await client.auditLog.create({
      data: {
        actorUserId: actor.id,
        action: input.action,
        resourceType: 'User',
        resourceId: input.resourceId,
        metadata: input.metadata,
      },
    });
  }

  private toResponse(user: UserRecord): UserResponse {
    return {
      id: user.id,
      username: user.username,
      status: user.status,
      profile: user.profile
        ? {
            displayName: user.profile.displayName,
            phone: user.profile.phone,
            email: user.profile.email,
            avatarUrl: user.profile.avatarUrl,
            departmentName: user.profile.departmentName,
            postName: user.profile.postName,
          }
        : null,
      roles: user.userRoles
        .map((userRole) => userRole.role)
        .sort((left, right) => left.id - right.id)
        .map((role) => ({
          id: role.id,
          code: role.code,
          name: role.name,
          description: role.description,
          isSystem: role.isSystem,
          isActive: role.isActive,
        })),
    };
  }
}

function normalizeIds(ids: readonly number[]): number[] {
  return [...new Set(ids)];
}

function pickDefined<T extends Record<string, unknown>>(input: T): Partial<T> {
  return Object.fromEntries(
    Object.entries(input).filter(([, value]) => value !== undefined),
  ) as Partial<T>;
}
