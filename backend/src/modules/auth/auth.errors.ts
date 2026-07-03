import { HttpException, HttpStatus } from '@nestjs/common';

import { ApiResponse } from '../../common/interfaces/api-response.interface';

export type AuthErrorCode =
  | 'BAD_REQUEST'
  | 'NOT_FOUND'
  | 'UNAUTHORIZED'
  | 'TOKEN_EXPIRED'
  | 'TOKEN_REVOKED'
  | 'USER_DISABLED'
  | 'NO_ACTIVE_ROLE'
  | 'FORBIDDEN';

export function createAuthException(
  code: AuthErrorCode,
  message: string,
  status: HttpStatus,
): HttpException {
  const response: ApiResponse<null> = {
    code,
    message,
    data: null,
  };

  return new HttpException(response, status);
}

export function throwAuthException(
  code: AuthErrorCode,
  message: string,
  status: HttpStatus,
): never {
  throw createAuthException(code, message, status);
}
