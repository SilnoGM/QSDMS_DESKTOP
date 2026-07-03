import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qsdms_desktop_frontend/modules/auth/auth_controller.dart';
import 'package:qsdms_desktop_frontend/modules/auth/models/auth_session.dart';
import 'package:qsdms_desktop_frontend/modules/auth/repositories/auth_repository.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/preference_storage.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('can/canAny/canAll 基于当前 session permissions 判断权限', () async {
    final controller = _buildController(
      repository: _FakeAuthRepository(
        loginSession: _session(permissions: {'system:user:list', 'order:read'}),
      ),
    );

    await controller.login(
      username: 'admin',
      password: 'secret',
      rememberLogin: false,
    );

    expect(controller.can('system:user:list'), isTrue);
    expect(controller.can('system:user:create'), isFalse);
    expect(controller.canAny({'system:user:create', 'order:read'}), isTrue);
    expect(controller.canAll({'system:user:list', 'order:read'}), isTrue);
    expect(
      controller.canAll({'system:user:list', 'system:user:create'}),
      isFalse,
    );
  });

  test('登录成功保存 token，关闭记住登录时清理 rememberLogin 和 lastUsername', () async {
    final secureStore = _MemorySecureTokenStore();
    final tokenStorage = TokenStorage(secureStore: secureStore);
    final preferenceStorage = PreferenceStorage();
    final controller = _buildController(
      tokenStorage: tokenStorage,
      preferenceStorage: preferenceStorage,
      repository: _FakeAuthRepository(loginSession: _session()),
    );

    await preferenceStorage.saveRememberedLogin(username: 'old-user');
    await controller.login(
      username: 'admin',
      password: 'secret',
      rememberLogin: false,
    );

    expect(tokenStorage.accessToken, 'access-token');
    expect(await tokenStorage.readRefreshToken(), 'refresh-token');
    expect(await preferenceStorage.readRememberLogin(), isFalse);
    expect(await preferenceStorage.readLastUsername(), isNull);
    expect(controller.isAuthenticated, isTrue);
  });
}

AuthController _buildController({
  TokenStorage? tokenStorage,
  PreferenceStorage? preferenceStorage,
  AuthRepository? repository,
}) {
  final resolvedTokenStorage =
      tokenStorage ?? TokenStorage(secureStore: _MemorySecureTokenStore());
  return AuthController(
    repository: repository ?? _FakeAuthRepository(loginSession: _session()),
    tokenStorage: resolvedTokenStorage,
    preferenceStorage: preferenceStorage ?? PreferenceStorage(),
  );
}

AuthSession _session({Set<String> permissions = const {'system:user:list'}}) {
  return AuthSession(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    user: const AuthUser(
      id: '1',
      username: 'admin',
      displayName: '管理员',
      raw: <String, dynamic>{},
    ),
    roles: const {'admin'},
    permissions: permissions,
    menus: const <Map<String, dynamic>>[],
  );
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required this.loginSession})
    : super(
        apiClient: ApiClient(
          dio: Dio(),
          tokenStorage: TokenStorage(secureStore: _MemorySecureTokenStore()),
        ),
      );

  final AuthSession loginSession;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    return loginSession;
  }
}

class _MemorySecureTokenStore implements SecureTokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
