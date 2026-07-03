import {
  ACTION_API_PERMISSION_MAP,
  ENABLED_PERMISSION_CODES,
  PERMISSION_SEEDS,
  ROLE_PERMISSION_CODE_MAP,
  SYSTEM_ROLE_CODES,
  isDevelopmentAdminSeedEnabled,
} from './permission-seed-data';

describe('permission seed data', () => {
  it('keeps permission codes unique', () => {
    const codes = PERMISSION_SEEDS.map((permission) => permission.code);

    expect(new Set(codes).size).toBe(codes.length);
  });

  it('keeps all action to api mappings backed by real permission codes', () => {
    const codes = new Set(PERMISSION_SEEDS.map((permission) => permission.code));

    for (const mapping of ACTION_API_PERMISSION_MAP) {
      expect(codes.has(mapping.actionCode)).toBe(true);
      expect(codes.has(mapping.apiCode)).toBe(true);
    }
  });

  it('grants every enabled permission to SUPER_ADMIN', () => {
    expect(ROLE_PERMISSION_CODE_MAP[SYSTEM_ROLE_CODES.SUPER_ADMIN]).toEqual(
      ENABLED_PERMISSION_CODES,
    );
  });

  it('keeps each role permission grant backed by a real enabled permission', () => {
    const enabledCodes = new Set<string>(ENABLED_PERMISSION_CODES);

    for (const permissionCodes of Object.values(ROLE_PERMISSION_CODE_MAP)) {
      for (const permissionCode of permissionCodes) {
        expect(enabledCodes.has(permissionCode)).toBe(true);
      }
    }
  });

  it('does not create the fixed development administrator in production by default', () => {
    expect(
      isDevelopmentAdminSeedEnabled({
        NODE_ENV: 'production',
      }),
    ).toBe(false);
  });

  it('creates the fixed development administrator only in development or by explicit opt-in', () => {
    expect(
      isDevelopmentAdminSeedEnabled({
        NODE_ENV: 'development',
      }),
    ).toBe(true);
    expect(
      isDevelopmentAdminSeedEnabled({
        NODE_ENV: 'production',
        QSDMS_SEED_DEV_ADMIN: 'true',
      }),
    ).toBe(true);
  });
});
