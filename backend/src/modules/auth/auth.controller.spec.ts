import 'reflect-metadata';

import { AuthController } from './auth.controller';
import { API_PERMISSION_KEY } from './decorators/api-permission.decorator';

describe('AuthController', () => {
  it('GET /auth/session 声明 api:auth:session 权限 metadata', () => {
    const permissionCodes = Reflect.getMetadata(
      API_PERMISSION_KEY,
      AuthController.prototype.session,
    );

    expect(permissionCodes).toEqual(['api:auth:session']);
  });
});
