export const SYSTEM_ROLE_CODES = {
  SUPER_ADMIN: 'SUPER_ADMIN',
  ADMIN: 'ADMIN',
  OPERATOR: 'OPERATOR',
  VIEWER: 'VIEWER',
} as const;

export type SystemRoleCode =
  (typeof SYSTEM_ROLE_CODES)[keyof typeof SYSTEM_ROLE_CODES];

export type PermissionSeedType = 'MENU' | 'ACTION' | 'API';

export type PermissionSeed = {
  readonly code: string;
  readonly name: string;
  readonly type: PermissionSeedType;
  readonly module: string;
  readonly description?: string;
  readonly sortOrder: number;
  readonly isSystem: boolean;
  readonly isActive: boolean;
};

export type RoleSeed = {
  readonly code: SystemRoleCode;
  readonly name: string;
  readonly description: string;
  readonly isSystem: boolean;
  readonly isActive: boolean;
};

export type ActionApiPermissionMapping = {
  readonly actionCode: string;
  readonly apiCode: string;
};

export type DevelopmentAdminSeedEnv = {
  readonly NODE_ENV?: string;
  readonly QSDMS_SEED_DEV_ADMIN?: string;
};

// 内置角色只负责首版系统级权限初始化；业务角色或组织权限后续应单独扩展，不在这里提前抽象。
export const ROLE_SEEDS = [
  {
    code: SYSTEM_ROLE_CODES.SUPER_ADMIN,
    name: '超级管理员',
    description: '系统维护者，自动拥有所有启用权限。',
    isSystem: true,
    isActive: true,
  },
  {
    code: SYSTEM_ROLE_CODES.ADMIN,
    name: '管理员',
    description: '负责系统设置、用户、角色和权限的日常管理。',
    isSystem: true,
    isActive: true,
  },
  {
    code: SYSTEM_ROLE_CODES.OPERATOR,
    name: '操作员',
    description: '负责日常业务数据处理，首版只授予基础入口权限。',
    isSystem: true,
    isActive: true,
  },
  {
    code: SYSTEM_ROLE_CODES.VIEWER,
    name: '只读用户',
    description: '只允许查看授权范围内的数据入口。',
    isSystem: true,
    isActive: true,
  },
] as const satisfies readonly RoleSeed[];

export const MENU_PERMISSION_SEEDS = [
  {
    code: 'menu:dashboard',
    name: '工作台菜单',
    type: 'MENU',
    module: 'dashboard',
    description: '允许查看工作台入口。',
    sortOrder: 10,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'menu:base-data',
    name: '基础数据菜单',
    type: 'MENU',
    module: 'base-data',
    description: '允许查看基础数据入口。',
    sortOrder: 20,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'menu:settings',
    name: '系统设置菜单',
    type: 'MENU',
    module: 'system',
    description: '允许查看系统设置入口。',
    sortOrder: 30,
    isSystem: true,
    isActive: true,
  },
] as const satisfies readonly PermissionSeed[];

export const ACTION_PERMISSION_SEEDS = [
  {
    code: 'system:user:list',
    name: '查看用户列表',
    type: 'ACTION',
    module: 'system',
    sortOrder: 110,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:user:create',
    name: '创建用户',
    type: 'ACTION',
    module: 'system',
    sortOrder: 120,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:user:update',
    name: '编辑用户',
    type: 'ACTION',
    module: 'system',
    sortOrder: 130,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:user:disable',
    name: '禁用用户',
    type: 'ACTION',
    module: 'system',
    sortOrder: 140,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:user:reset-password',
    name: '重置用户密码',
    type: 'ACTION',
    module: 'system',
    sortOrder: 150,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:user:assign-roles',
    name: '分配用户角色',
    type: 'ACTION',
    module: 'system',
    sortOrder: 160,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:role:list',
    name: '查看角色列表',
    type: 'ACTION',
    module: 'system',
    sortOrder: 210,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:role:create',
    name: '创建角色',
    type: 'ACTION',
    module: 'system',
    sortOrder: 220,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:role:update',
    name: '编辑角色',
    type: 'ACTION',
    module: 'system',
    sortOrder: 230,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:role:assign-permissions',
    name: '分配角色权限',
    type: 'ACTION',
    module: 'system',
    sortOrder: 240,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'system:permission:list',
    name: '查看权限列表',
    type: 'ACTION',
    module: 'system',
    sortOrder: 310,
    isSystem: true,
    isActive: true,
  },
] as const satisfies readonly PermissionSeed[];

export const API_PERMISSION_SEEDS = [
  {
    code: 'api:users:list',
    name: '用户列表接口',
    type: 'API',
    module: 'system',
    sortOrder: 1110,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:users:create',
    name: '创建用户接口',
    type: 'API',
    module: 'system',
    sortOrder: 1120,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:users:detail',
    name: '用户详情接口',
    type: 'API',
    module: 'system',
    sortOrder: 1130,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:users:update',
    name: '编辑用户接口',
    type: 'API',
    module: 'system',
    sortOrder: 1140,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:users:update-status',
    name: '更新用户状态接口',
    type: 'API',
    module: 'system',
    sortOrder: 1150,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:users:reset-password',
    name: '重置用户密码接口',
    type: 'API',
    module: 'system',
    sortOrder: 1160,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:users:assign-roles',
    name: '分配用户角色接口',
    type: 'API',
    module: 'system',
    sortOrder: 1170,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:roles:list',
    name: '角色列表接口',
    type: 'API',
    module: 'system',
    sortOrder: 1210,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:roles:create',
    name: '创建角色接口',
    type: 'API',
    module: 'system',
    sortOrder: 1220,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:roles:update',
    name: '编辑角色接口',
    type: 'API',
    module: 'system',
    sortOrder: 1230,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:roles:assign-permissions',
    name: '分配角色权限接口',
    type: 'API',
    module: 'system',
    sortOrder: 1240,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:permissions:list',
    name: '权限列表接口',
    type: 'API',
    module: 'system',
    sortOrder: 1310,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:menus:me',
    name: '当前用户菜单接口',
    type: 'API',
    module: 'system',
    description: '认证用户读取自身可见菜单。',
    sortOrder: 1410,
    isSystem: true,
    isActive: true,
  },
  {
    code: 'api:auth:session',
    name: '当前会话快照接口',
    type: 'API',
    module: 'system',
    description: '认证用户读取自身用户、角色、权限和菜单快照。',
    sortOrder: 1510,
    isSystem: true,
    isActive: true,
  },
] as const satisfies readonly PermissionSeed[];

export const PERMISSION_SEEDS = [
  ...MENU_PERMISSION_SEEDS,
  ...ACTION_PERMISSION_SEEDS,
  ...API_PERMISSION_SEEDS,
] as const satisfies readonly PermissionSeed[];

export const ENABLED_PERMISSION_CODES = PERMISSION_SEEDS.filter(
  (permission) => permission.isActive,
).map((permission) => permission.code);

// ACTION/API 映射是前端按钮权限与后端接口权限的对账表，后续新增业务动作时必须同步维护。
export const ACTION_API_PERMISSION_MAP = [
  { actionCode: 'system:user:list', apiCode: 'api:users:list' },
  { actionCode: 'system:user:create', apiCode: 'api:users:create' },
  { actionCode: 'system:user:update', apiCode: 'api:users:update' },
  { actionCode: 'system:user:disable', apiCode: 'api:users:update-status' },
  {
    actionCode: 'system:user:reset-password',
    apiCode: 'api:users:reset-password',
  },
  {
    actionCode: 'system:user:assign-roles',
    apiCode: 'api:users:assign-roles',
  },
  { actionCode: 'system:role:list', apiCode: 'api:roles:list' },
  { actionCode: 'system:role:create', apiCode: 'api:roles:create' },
  { actionCode: 'system:role:update', apiCode: 'api:roles:update' },
  {
    actionCode: 'system:role:assign-permissions',
    apiCode: 'api:roles:assign-permissions',
  },
  {
    actionCode: 'system:permission:list',
    apiCode: 'api:permissions:list',
  },
] as const satisfies readonly ActionApiPermissionMapping[];

const ADMIN_PERMISSION_CODES = ENABLED_PERMISSION_CODES;

const OPERATOR_PERMISSION_CODES = [
  'menu:dashboard',
  'menu:base-data',
  'api:menus:me',
  'api:auth:session',
] as const;

const VIEWER_PERMISSION_CODES = [
  'menu:dashboard',
  'menu:base-data',
  'api:menus:me',
  'api:auth:session',
] as const;

// SUPER_ADMIN 使用全部启用权限；其他内置角色保持保守授权，避免首版把管理能力扩散给普通账号。
export const ROLE_PERMISSION_CODE_MAP: Readonly<
  Record<SystemRoleCode, readonly string[]>
> = {
  [SYSTEM_ROLE_CODES.SUPER_ADMIN]: ENABLED_PERMISSION_CODES,
  [SYSTEM_ROLE_CODES.ADMIN]: ADMIN_PERMISSION_CODES,
  [SYSTEM_ROLE_CODES.OPERATOR]: OPERATOR_PERMISSION_CODES,
  [SYSTEM_ROLE_CODES.VIEWER]: VIEWER_PERMISSION_CODES,
};

export const DEVELOPMENT_ADMIN_SEED = {
  username: 'admin',
  password: 'admin',
  displayName: '系统管理员',
} as const;

// 固定 admin/admin 只服务本地开发和显式初始化，生产环境默认不会创建该账号。
export function isDevelopmentAdminSeedEnabled(
  env: DevelopmentAdminSeedEnv,
): boolean {
  return (
    env.NODE_ENV === 'development' || env.QSDMS_SEED_DEV_ADMIN === 'true'
  );
}
