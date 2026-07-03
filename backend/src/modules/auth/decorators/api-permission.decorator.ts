import { SetMetadata } from '@nestjs/common';

export const API_PERMISSION_KEY = 'qsdms:api-permissions';

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
