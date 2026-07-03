import 'dart:convert';
import 'dart:typed_data';

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

  test('登录和 refresh callback 只把无 token snapshot 放进 session', () async {
    final tokenStorage = TokenStorage(secureStore: _MemorySecureTokenStore());
    final controller = _buildController(
      tokenStorage: tokenStorage,
      repository: _FakeAuthRepository(loginSession: _session()),
    );

    await controller.login(
      username: 'admin',
      password: 'secret',
      rememberLogin: false,
    );

    expect(controller.session.value, isA<AuthSessionSnapshot>());
    expect(_exposesSensitiveTokenFields(controller.session.value), isFalse);
    expect(tokenStorage.accessToken, 'access-token');
    expect(await tokenStorage.readRefreshToken(), 'refresh-token');

    controller.applyRefreshedSessionData(
      _sessionResponseData(
        accessToken: 'callback-access',
        refreshToken: 'callback-refresh',
        username: 'callback-admin',
        permissions: {'system:callback'},
      ),
    );

    expect(controller.session.value?.user.username, 'callback-admin');
    expect(controller.permissions, {'system:callback'});
    expect(_exposesSensitiveTokenFields(controller.session.value), isFalse);
    expect(tokenStorage.accessToken, 'access-token');
    expect(await tokenStorage.readRefreshToken(), 'refresh-token');
  });

  test('后端 user 子对象的敏感字段不会进入 session user raw', () {
    final controller = _buildController();

    controller.applyRefreshedSessionData(
      _sessionResponseData(
        accessToken: 'callback-access',
        refreshToken: 'callback-refresh',
        username: 'callback-admin',
        permissions: {'system:callback'},
        userOverrides: const <String, dynamic>{
          'accessToken': 'nested-access',
          'RefreshToken': 'nested-refresh',
          'TOKEN': 'nested-token',
          'password': 'secret',
          'PasswordHash': 'hash',
          'refreshTokenHash': 'refresh-hash',
          'email': 'admin@example.com',
        },
      ),
    );

    final raw = controller.session.value?.user.raw;
    final normalizedRawKeys = raw?.keys.map((key) => key.toLowerCase()).toSet();

    expect(raw, containsPair('email', 'admin@example.com'));
    for (final sensitiveKey in <String>{
      'accesstoken',
      'refreshtoken',
      'token',
      'password',
      'passwordhash',
      'refreshtokenhash',
    }) {
      expect(normalizedRawKeys, isNot(contains(sensitiveKey)));
    }
  });

  test('restoreSession 成功保存新 token 和无 token snapshot', () async {
    final secureStore = _MemorySecureTokenStore();
    final tokenStorage = TokenStorage(secureStore: secureStore);
    await tokenStorage.saveTokens(
      accessToken: 'stale-access',
      refreshToken: 'stored-refresh',
    );
    final repository = _FakeAuthRepository(
      loginSession: _session(),
      refreshSessionResult: _session(
        accessToken: 'restored-access',
        refreshToken: 'restored-refresh',
        permissions: {'system:restored'},
      ),
    );
    final controller = _buildController(
      tokenStorage: tokenStorage,
      repository: repository,
    );

    await controller.restoreSession();

    expect(repository.receivedRefreshToken, 'stored-refresh');
    expect(tokenStorage.accessToken, 'restored-access');
    expect(await tokenStorage.readRefreshToken(), 'restored-refresh');
    expect(controller.permissions, {'system:restored'});
    expect(_exposesSensitiveTokenFields(controller.session.value), isFalse);
  });

  test('restoreSession 失败清理本地 token 和 session', () async {
    final secureStore = _MemorySecureTokenStore();
    final tokenStorage = TokenStorage(secureStore: secureStore);
    await tokenStorage.saveTokens(
      accessToken: 'stale-access',
      refreshToken: 'stored-refresh',
    );
    final controller = _buildController(
      tokenStorage: tokenStorage,
      repository: _FakeAuthRepository(
        loginSession: _session(),
        refreshError: StateError('refresh failed'),
      ),
    )..session.value = _session().snapshot;

    await controller.restoreSession();

    expect(tokenStorage.accessToken, isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
    expect(controller.session.value, isNull);
  });

  test('logout 调用后端时带 access token 并清理本地 token', () async {
    final secureStore = _MemorySecureTokenStore();
    final tokenStorage = TokenStorage(secureStore: secureStore);
    await tokenStorage.saveTokens(
      accessToken: 'logout-access',
      refreshToken: 'logout-refresh',
    );
    final adapter = _LogoutAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'))
      ..httpClientAdapter = adapter;
    final apiClient = ApiClient(dio: dio, tokenStorage: tokenStorage);
    final controller = _buildController(
      tokenStorage: tokenStorage,
      repository: AuthRepository(apiClient: apiClient),
    )..session.value = _session().snapshot;

    await controller.logout();

    expect(adapter.logoutCount, 1);
    expect(adapter.logoutAuthorizationHeaders, <Object?>[
      'Bearer logout-access',
    ]);
    expect(tokenStorage.accessToken, isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
    expect(controller.session.value, isNull);
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

AuthTokenResult _session({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  String username = 'admin',
  Set<String> permissions = const {'system:user:list'},
}) {
  return AuthTokenResult(
    accessToken: accessToken,
    refreshToken: refreshToken,
    snapshot: AuthSessionSnapshot(
      user: AuthUser(
        id: '1',
        username: username,
        displayName: '管理员',
        raw: const <String, dynamic>{},
      ),
      roles: const {'admin'},
      permissions: permissions,
      menus: const <Map<String, dynamic>>[],
    ),
  );
}

Map<String, dynamic> _sessionResponseData({
  required String accessToken,
  required String refreshToken,
  required String username,
  required Set<String> permissions,
  Map<String, dynamic> userOverrides = const <String, dynamic>{},
}) {
  return <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': <String, dynamic>{
      'id': '1',
      'username': username,
      ...userOverrides,
    },
    'roles': <String>['admin'],
    'permissions': permissions.toList(growable: false),
    'menus': <Map<String, dynamic>>[],
  };
}

bool _exposesSensitiveTokenFields(Object? value) {
  if (value == null) {
    return false;
  }

  try {
    final dynamic session = value;
    session.accessToken;
    session.refreshToken;
    return true;
  } on NoSuchMethodError {
    return false;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    required this.loginSession,
    this.refreshSessionResult,
    this.refreshError,
  }) : super(
         apiClient: ApiClient(
           dio: Dio(),
           tokenStorage: TokenStorage(secureStore: _MemorySecureTokenStore()),
         ),
       );

  final AuthTokenResult loginSession;
  final AuthTokenResult? refreshSessionResult;
  final Object? refreshError;
  String? receivedRefreshToken;

  @override
  Future<AuthTokenResult> login({
    required String username,
    required String password,
  }) async {
    return loginSession;
  }

  @override
  Future<AuthTokenResult> refreshSession(String refreshToken) async {
    receivedRefreshToken = refreshToken;
    final error = refreshError;
    if (error != null) {
      throw error;
    }
    return refreshSessionResult ?? loginSession;
  }
}

class _LogoutAdapter implements HttpClientAdapter {
  int logoutCount = 0;
  final logoutAuthorizationHeaders = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/logout') {
      logoutCount++;
      final authorization = options.headers['authorization'];
      logoutAuthorizationHeaders.add(authorization);
      final authorized = authorization == 'Bearer logout-access';
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'code': authorized ? 0 : 401,
          'message': authorized ? 'ok' : 'unauthorized',
        }),
        authorized ? 200 : 401,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'code': 404, 'message': 'not found'}),
      404,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
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
