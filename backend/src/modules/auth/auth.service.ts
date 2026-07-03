import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PermissionType, UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';
import { randomBytes } from 'crypto';

import { PrismaService } from '../../database/prisma.service';
import {
  createRefreshTokenExpiresAt,
  getJwtAccessTokenExpiresIn,
  getJwtAccessTokenSecret,
} from './auth.config';
import { throwAuthException } from './auth.errors';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import {
  AuthMenu,
  AuthPermission,
  AuthRole,
  AuthSessionSnapshot,
  AuthUser,
  LoginResult,
  LogoutResult,
} from './models/auth-session.model';
import { CurrentUserPayload } from './models/current-user.model';
import { JwtPayload } from './models/jwt-payload.model';

export type AuthRequestContext = {
  readonly ipAddress?: string;
  readonly userAgent?: string;
};

type UserProfileRecord = {
  readonly displayName: string;
  readonly phone: string | null;
  readonly email: string | null;
  readonly avatarUrl: string | null;
  readonly departmentName: string | null;
  readonly postName: string | null;
};

type PermissionRecord = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly type: PermissionType;
  readonly module: string;
  readonly description: string | null;
  readonly sortOrder: number;
  readonly isActive: boolean;
};

type RolePermissionRecord = {
  readonly permission: PermissionRecord;
};

type RoleRecord = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly description: string | null;
  readonly isSystem: boolean;
  readonly isActive: boolean;
  readonly rolePermissions: readonly RolePermissionRecord[];
};

type UserRoleRecord = {
  readonly role: RoleRecord;
};

type AuthUserRecord = {
  readonly id: string;
  readonly username: string;
  readonly passwordHash: string;
  readonly status: UserStatus;
  readonly tokenVersion: number;
  readonly profile: UserProfileRecord | null;
  readonly userRoles: readonly UserRoleRecord[];
};

type RefreshSessionRecord = {
  readonly id: string;
  readonly userId: string;
  readonly refreshTokenHash: string;
  readonly expiresAt: Date;
  readonly revokedAt: Date | null;
  readonly user: AuthUserRecord;
};

type ParsedRefreshToken = {
  readonly sessionId: string;
  readonly secret: string;
};

const MENU_DEFINITIONS: readonly AuthMenu[] = [
  {
    key: 'dashboard',
    title: '工作台',
    route: '/dashboard',
    icon: 'LayoutDashboard',
    permissionCode: 'menu:dashboard',
    sortOrder: 10,
    children: [],
  },
  {
    key: 'base-data',
    title: '基础数据',
    route: '/base-data',
    icon: 'Database',
    permissionCode: 'menu:base-data',
    sortOrder: 20,
    children: [],
  },
  {
    key: 'system-settings',
    title: '系统设置',
    route: '/system',
    icon: 'Settings',
    permissionCode: 'menu:settings',
    sortOrder: 30,
    children: [],
  },
];

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async login(
    dto: LoginDto,
    context: AuthRequestContext = {},
  ): Promise<LoginResult> {
    const user = await this.findUserByUsername(dto.username);

    if (!user) {
      throwAuthException(
        'UNAUTHORIZED',
        'Invalid username or password.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    this.assertActiveUser(user);

    const passwordMatched = await argon2.verify(user.passwordHash, dto.password);

    if (!passwordMatched) {
      throwAuthException(
        'UNAUTHORIZED',
        'Invalid username or password.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    const snapshot = this.createSessionSnapshot(user);
    const [accessToken, refreshToken] = await Promise.all([
      this.signAccessToken(user),
      this.createRefreshSession(user.id, user.tokenVersion, context),
    ]);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    return {
      accessToken,
      refreshToken,
      ...snapshot,
    };
  }

  async refresh(dto: RefreshTokenDto): Promise<LoginResult> {
    const parsedToken = this.parseRefreshToken(dto.refreshToken);
    const refreshSession = await this.findRefreshSession(parsedToken.sessionId);

    if (!refreshSession || refreshSession.revokedAt) {
      throwAuthException(
        'TOKEN_REVOKED',
        'Refresh token has been revoked.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    if (refreshSession.expiresAt.getTime() <= Date.now()) {
      throwAuthException(
        'TOKEN_EXPIRED',
        'Refresh token expired.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    this.assertActiveUser(refreshSession.user);
    this.assertRefreshTokenVersion(parsedToken.secret, refreshSession.user);

    const secretMatched = await argon2.verify(
      refreshSession.refreshTokenHash,
      parsedToken.secret,
    );

    if (!secretMatched) {
      throwAuthException(
        'TOKEN_REVOKED',
        'Refresh token has been revoked.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    const snapshot = this.createSessionSnapshot(refreshSession.user);
    const nextRefreshSecret = this.createRefreshSecret(
      refreshSession.user.tokenVersion,
    );
    const nextRefreshTokenHash = await argon2.hash(nextRefreshSecret);

    // refresh token 使用同一个 sessionId 轮换 secret；数据库只保存最新 secret 的 hash，
    // 因此旧 refresh token 会在下一次校验时立即失效。
    await this.prisma.refreshSession.update({
      where: { id: refreshSession.id },
      data: {
        refreshTokenHash: nextRefreshTokenHash,
      },
    });

    return {
      accessToken: await this.signAccessToken(refreshSession.user),
      refreshToken: this.formatRefreshToken(
        refreshSession.id,
        nextRefreshSecret,
      ),
      ...snapshot,
    };
  }

  async logout(
    currentUser: CurrentUserPayload,
    dto: LogoutDto,
  ): Promise<LogoutResult> {
    const parsedToken = dto.refreshToken
      ? this.tryParseRefreshToken(dto.refreshToken)
      : null;

    if (parsedToken) {
      await this.prisma.refreshSession.updateMany({
        where: {
          id: parsedToken.sessionId,
          userId: currentUser.id,
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
        },
      });
    }

    return { success: true };
  }

  async getMe(currentUser: CurrentUserPayload): Promise<AuthUser> {
    const snapshot = await this.getSessionSnapshot(currentUser.id);

    return snapshot.user;
  }

  async getPermissions(
    currentUser: CurrentUserPayload,
  ): Promise<AuthPermission[]> {
    const snapshot = await this.getSessionSnapshot(currentUser.id);

    return snapshot.permissions;
  }

  async getSessionSnapshot(userId: string): Promise<AuthSessionSnapshot> {
    const user = await this.findUserById(userId);

    if (!user) {
      throwAuthException(
        'UNAUTHORIZED',
        'User not found.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    this.assertActiveUser(user);

    return this.createSessionSnapshot(user);
  }

  private async findUserByUsername(
    username: string,
  ): Promise<AuthUserRecord | null> {
    return this.prisma.user.findUnique({
      where: { username },
      include: AUTH_USER_INCLUDE,
    }) as Promise<AuthUserRecord | null>;
  }

  private async findUserById(userId: string): Promise<AuthUserRecord | null> {
    return this.prisma.user.findUnique({
      where: { id: userId },
      include: AUTH_USER_INCLUDE,
    }) as Promise<AuthUserRecord | null>;
  }

  private async findRefreshSession(
    sessionId: string,
  ): Promise<RefreshSessionRecord | null> {
    return this.prisma.refreshSession.findUnique({
      where: { id: sessionId },
      include: {
        user: {
          include: AUTH_USER_INCLUDE,
        },
      },
    }) as Promise<RefreshSessionRecord | null>;
  }

  private assertActiveUser(user: AuthUserRecord): void {
    if (user.status !== UserStatus.ACTIVE) {
      throwAuthException(
        'USER_DISABLED',
        'User is disabled or locked.',
        HttpStatus.FORBIDDEN,
      );
    }
  }

  private createSessionSnapshot(user: AuthUserRecord): AuthSessionSnapshot {
    const activeRoles = user.userRoles
      .map((userRole) => userRole.role)
      .filter((role) => role.isActive)
      .sort((left, right) => left.id - right.id);

    if (activeRoles.length === 0) {
      throwAuthException(
        'NO_ACTIVE_ROLE',
        'User has no active role.',
        HttpStatus.FORBIDDEN,
      );
    }

    const permissions = this.collectPermissions(activeRoles);

    return {
      user: this.sanitizeUser(user),
      roles: activeRoles.map((role) => this.sanitizeRole(role)),
      permissions,
      menus: this.buildMenus(permissions),
    };
  }

  private collectPermissions(
    roles: readonly RoleRecord[],
  ): AuthPermission[] {
    const permissionsByCode = new Map<string, AuthPermission>();

    for (const role of roles) {
      for (const rolePermission of role.rolePermissions) {
        const permission = rolePermission.permission;

        if (!permission.isActive || permissionsByCode.has(permission.code)) {
          continue;
        }

        permissionsByCode.set(permission.code, {
          id: permission.id,
          code: permission.code,
          name: permission.name,
          type: permission.type,
          module: permission.module,
          description: permission.description,
          sortOrder: permission.sortOrder,
        });
      }
    }

    return [...permissionsByCode.values()].sort(
      (left, right) =>
        left.sortOrder - right.sortOrder || left.code.localeCompare(right.code),
    );
  }

  private buildMenus(permissions: readonly AuthPermission[]): AuthMenu[] {
    const permissionCodes = new Set(
      permissions
        .filter((permission) => permission.code.startsWith('menu:'))
        .map((permission) => permission.code),
    );

    return MENU_DEFINITIONS.filter((menu) =>
      permissionCodes.has(menu.permissionCode),
    ).map((menu) => ({
      ...menu,
      // 首版菜单最多两级；当前三个入口都是一级，保留 children 字段给前端稳定消费。
      children: [],
    }));
  }

  private sanitizeUser(user: AuthUserRecord): AuthUser {
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
    };
  }

  private sanitizeRole(role: RoleRecord): AuthRole {
    return {
      id: role.id,
      code: role.code,
      name: role.name,
      description: role.description,
      isSystem: role.isSystem,
      isActive: role.isActive,
    };
  }

  private async signAccessToken(user: AuthUserRecord): Promise<string> {
    const payload: JwtPayload = {
      sub: user.id,
      username: user.username,
      tokenVersion: user.tokenVersion,
    };

    return this.jwtService.signAsync(payload, {
      secret: getJwtAccessTokenSecret(this.configService),
      expiresIn: getJwtAccessTokenExpiresIn(this.configService),
    });
  }

  private async createRefreshSession(
    userId: string,
    tokenVersion: number,
    context: AuthRequestContext,
  ): Promise<string> {
    const refreshSecret = this.createRefreshSecret(tokenVersion);
    const refreshTokenHash = await argon2.hash(refreshSecret);
    const session = await this.prisma.refreshSession.create({
      data: {
        userId,
        refreshTokenHash,
        userAgent: context.userAgent,
        ipAddress: context.ipAddress,
        expiresAt: createRefreshTokenExpiresAt(),
      },
    });

    return this.formatRefreshToken(session.id, refreshSecret);
  }

  private parseRefreshToken(refreshToken: string): ParsedRefreshToken {
    const parsedToken = this.tryParseRefreshToken(refreshToken);

    if (!parsedToken) {
      throwAuthException(
        'TOKEN_REVOKED',
        'Invalid refresh token.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    return parsedToken;
  }

  private tryParseRefreshToken(
    refreshToken: string,
  ): ParsedRefreshToken | null {
    const separatorIndex = refreshToken.indexOf('.');

    if (separatorIndex <= 0 || separatorIndex === refreshToken.length - 1) {
      return null;
    }

    return {
      sessionId: refreshToken.slice(0, separatorIndex),
      secret: refreshToken.slice(separatorIndex + 1),
    };
  }

  private formatRefreshToken(sessionId: string, secret: string): string {
    return `${sessionId}.${secret}`;
  }

  private createRandomSecret(): string {
    return randomBytes(48).toString('base64url');
  }

  private createRefreshSecret(tokenVersion: number): string {
    // refresh_sessions 当前不保存 tokenVersion；把签发时版本放进 secret，再整体做 argon2 hash，
    // 可在不改 schema 的前提下让 tokenVersion 变更立即吊销旧 refresh token。
    return `tv${tokenVersion}.${this.createRandomSecret()}`;
  }

  private assertRefreshTokenVersion(
    refreshSecret: string,
    user: AuthUserRecord,
  ): void {
    const tokenVersion = this.parseRefreshTokenVersion(refreshSecret);

    if (tokenVersion !== user.tokenVersion) {
      throwAuthException(
        'TOKEN_REVOKED',
        'Refresh token has been revoked.',
        HttpStatus.UNAUTHORIZED,
      );
    }
  }

  private parseRefreshTokenVersion(refreshSecret: string): number | null {
    const match = /^tv(?<tokenVersion>\d+)\./.exec(refreshSecret);

    if (!match?.groups?.tokenVersion) {
      return null;
    }

    return Number(match.groups.tokenVersion);
  }
}

const AUTH_USER_INCLUDE = {
  profile: true,
  userRoles: {
    include: {
      role: {
        include: {
          rolePermissions: {
            include: {
              permission: true,
            },
          },
        },
      },
    },
  },
} as const;
