import { SetMetadata } from '@nestjs/common';

export const API_PERMISSION_KEY = 'qsdms:api-permissions';
export const AUTHENTICATED_ONLY_KEY = 'qsdms:authenticated-only';

type ApiPermissionInput = string | readonly string[];

/// 声明接口级权限码。
///
/// 多个权限码首版按 all-of 处理：调用者必须同时拥有全部声明的 API 权限。
export function ApiPermission(
  ...permissionCodes: readonly ApiPermissionInput[]
): MethodDecorator & ClassDecorator {
  const normalizedPermissionCodes = permissionCodes.flatMap((permissionCode) =>
    Array.isArray(permissionCode) ? permissionCode : [permissionCode],
  );

  return SetMetadata(API_PERMISSION_KEY, normalizedPermissionCodes);
}

/// 声明接口只要求有效登录态，不要求具体 API 权限。
///
/// 该 decorator 只能用于 logout/me/permissions 这类“登录用户自查”接口；
/// 管理接口必须继续使用 @ApiPermission，避免漏标时被全局权限 guard 放行。
export function AuthenticatedOnly(): MethodDecorator & ClassDecorator {
  return SetMetadata(AUTHENTICATED_ONLY_KEY, true);
}
