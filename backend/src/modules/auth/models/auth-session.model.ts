export type AuthUserProfile = {
  readonly displayName: string;
  readonly phone: string | null;
  readonly email: string | null;
  readonly avatarUrl: string | null;
  readonly departmentName: string | null;
  readonly postName: string | null;
};

export type AuthUser = {
  readonly id: string;
  readonly username: string;
  readonly status: string;
  readonly profile: AuthUserProfile | null;
};

export type AuthRole = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly description: string | null;
  readonly isSystem: boolean;
  readonly isActive: boolean;
};

export type AuthPermission = {
  readonly id: number;
  readonly code: string;
  readonly name: string;
  readonly type: string;
  readonly module: string;
  readonly description: string | null;
  readonly sortOrder: number;
};

export type AuthMenu = {
  readonly key: string;
  readonly title: string;
  readonly route: string;
  readonly icon: string;
  readonly permissionCode: string;
  readonly sortOrder: number;
  readonly children: AuthMenu[];
};

export type AuthSessionSnapshot = {
  readonly user: AuthUser;
  readonly roles: AuthRole[];
  readonly permissions: AuthPermission[];
  readonly menus: AuthMenu[];
};

export type LoginResult = AuthSessionSnapshot & {
  readonly accessToken: string;
  readonly refreshToken: string;
};

export type LogoutResult = {
  readonly success: boolean;
};
