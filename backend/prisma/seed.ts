import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
import {
  DEVELOPMENT_ADMIN_SEED,
  PERMISSION_SEEDS,
  ROLE_PERMISSION_CODE_MAP,
  ROLE_SEEDS,
  SYSTEM_ROLE_CODES,
  isDevelopmentAdminSeedEnabled,
} from '../src/modules/authz/permission-seed-data';

function createPrismaClient(): PrismaClient {
  const connectionString = process.env['DATABASE_URL'];

  if (!connectionString) {
    throw new Error('DATABASE_URL is required to run the Prisma seed script.');
  }

  return new PrismaClient({
    adapter: new PrismaPg({ connectionString }),
  });
}

function formatSeedError(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error);

  // seed 失败时只输出脱敏后的错误摘要，避免数据库连接串或 token 类文本进入日志。
  return message
    .replace(/postgres(?:ql)?:\/\/\S+/gi, '[REDACTED_DATABASE_URL]')
    .replace(/token=\S+/gi, 'token=[REDACTED]');
}

async function syncRoles(prisma: PrismaClient): Promise<void> {
  for (const role of ROLE_SEEDS) {
    await prisma.role.upsert({
      where: { code: role.code },
      update: {
        name: role.name,
        description: role.description,
        isSystem: role.isSystem,
        isActive: role.isActive,
      },
      create: role,
    });
  }
}

async function syncPermissions(prisma: PrismaClient): Promise<void> {
  for (const permission of PERMISSION_SEEDS) {
    const description =
      'description' in permission ? permission.description : undefined;

    await prisma.permission.upsert({
      where: { code: permission.code },
      update: {
        name: permission.name,
        type: permission.type,
        module: permission.module,
        description,
        sortOrder: permission.sortOrder,
        isSystem: permission.isSystem,
        isActive: permission.isActive,
      },
      create: {
        code: permission.code,
        name: permission.name,
        type: permission.type,
        module: permission.module,
        description,
        sortOrder: permission.sortOrder,
        isSystem: permission.isSystem,
        isActive: permission.isActive,
      },
    });
  }
}

async function syncRolePermissions(prisma: PrismaClient): Promise<void> {
  const [roles, enabledPermissions] = await Promise.all([
    prisma.role.findMany({
      where: { code: { in: ROLE_SEEDS.map((role) => role.code) } },
      select: { id: true, code: true },
    }),
    prisma.permission.findMany({
      where: { isActive: true },
      select: { id: true, code: true },
      orderBy: { sortOrder: 'asc' },
    }),
  ]);

  const permissionIdByCode = new Map(
    enabledPermissions.map((permission) => [permission.code, permission.id]),
  );

  for (const role of roles) {
    const roleCode = role.code as keyof typeof ROLE_PERMISSION_CODE_MAP;
    const permissionCodes =
      role.code === SYSTEM_ROLE_CODES.SUPER_ADMIN
        ? enabledPermissions.map((permission) => permission.code)
        : ROLE_PERMISSION_CODE_MAP[roleCode];

    const permissionIds = permissionCodes.map((permissionCode) => {
      const permissionId = permissionIdByCode.get(permissionCode);

      if (!permissionId) {
        throw new Error(
          `Missing enabled permission for role seed: ${role.code} -> ${permissionCode}`,
        );
      }

      return permissionId;
    });

    // 内置角色的授权集合由 seed 负责维护；重复执行时先清掉不再属于该角色的授权，再补齐缺失授权。
    await prisma.$transaction([
      prisma.rolePermission.deleteMany({
        where: {
          roleId: role.id,
          permissionId: { notIn: permissionIds },
        },
      }),
      prisma.rolePermission.createMany({
        data: permissionIds.map((permissionId) => ({
          roleId: role.id,
          permissionId,
        })),
        skipDuplicates: true,
      }),
    ]);
  }
}

async function createDevelopmentAdmin(prisma: PrismaClient): Promise<void> {
  if (!isDevelopmentAdminSeedEnabled(process.env)) {
    console.log('[seed] development administrator skipped');
    return;
  }

  const existingAdmin = await prisma.user.findUnique({
    where: { username: DEVELOPMENT_ADMIN_SEED.username },
    select: { id: true },
  });

  const admin =
    existingAdmin ??
    (await prisma.user.create({
      data: {
        username: DEVELOPMENT_ADMIN_SEED.username,
        passwordHash: await argon2.hash(DEVELOPMENT_ADMIN_SEED.password, {
          type: argon2.argon2id,
        }),
        profile: {
          create: {
            displayName: DEVELOPMENT_ADMIN_SEED.displayName,
          },
        },
      },
      select: { id: true },
    }));

  const superAdminRole = await prisma.role.findUniqueOrThrow({
    where: { code: SYSTEM_ROLE_CODES.SUPER_ADMIN },
    select: { id: true },
  });

  await prisma.userRole.upsert({
    where: {
      userId_roleId: {
        userId: admin.id,
        roleId: superAdminRole.id,
      },
    },
    update: {},
    create: {
      userId: admin.id,
      roleId: superAdminRole.id,
    },
  });

  console.log(
    existingAdmin
      ? '[seed] development administrator already exists'
      : '[seed] development administrator created',
  );
}

async function main(): Promise<void> {
  const prisma = createPrismaClient();

  try {
    await syncRoles(prisma);
    await syncPermissions(prisma);
    await syncRolePermissions(prisma);
    await createDevelopmentAdmin(prisma);
    console.log('[seed] RBAC seed completed');
  } finally {
    await prisma.$disconnect();
  }
}

void main().catch((error: unknown) => {
  console.error('[seed] RBAC seed failed');
  console.error(formatSeedError(error));
  process.exitCode = 1;
});
