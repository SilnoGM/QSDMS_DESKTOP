import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  test(
    'login/refresh 跳过 Authorization 且 401 不触发 refresh，logout 带 Bearer token',
    () async {
      final secureStore = _MemorySecureTokenStore();
      final tokenStorage = TokenStorage(secureStore: secureStore);
      await tokenStorage.saveTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );
      final adapter = _AuthEndpointBoundaryAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio, tokenStorage: tokenStorage);

      await expectLater(
        client.dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: <String, dynamic>{'username': 'admin', 'password': 'secret'},
          options: Options(
            extra: const <String, Object>{ApiClient.skipAuthExtraKey: true},
          ),
        ),
        throwsA(isA<DioException>()),
      );

      expect(adapter.loginAuthorizationHeaders, <Object?>[null]);
      expect(adapter.refreshEndpointCount, 0);

      await expectLater(
        client.dio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: <String, dynamic>{'refreshToken': 'refresh-token'},
          options: Options(
            extra: const <String, Object>{ApiClient.skipAuthExtraKey: true},
          ),
        ),
        throwsA(isA<DioException>()),
      );

      expect(adapter.refreshAuthorizationHeaders, <Object?>[null]);
      expect(adapter.refreshEndpointCount, 1);

      await client.dio.post<Map<String, dynamic>>('/auth/logout');

      expect(adapter.logoutAuthorizationHeaders, <Object?>[
        'Bearer access-token',
      ]);
      expect(adapter.refreshEndpointCount, 1);
    },
  );

  test('多个并发 401 只触发一次 refresh，成功后重放原请求', () async {
    final secureStore = _MemorySecureTokenStore();
    final tokenStorage = TokenStorage(secureStore: secureStore);
    await tokenStorage.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    final adapter = _RefreshAdapter(refreshSucceeds: true);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'))
      ..httpClientAdapter = adapter;

    final client = ApiClient(dio: dio, tokenStorage: tokenStorage);

    final responses = await Future.wait([
      client.dio.get<Map<String, dynamic>>('/protected'),
      client.dio.get<Map<String, dynamic>>('/protected'),
    ]);

    expect(adapter.refreshCount, 1);
    expect(adapter.protectedCount, 4);
    expect(tokenStorage.accessToken, 'new-access');
    expect(await tokenStorage.readRefreshToken(), 'new-refresh');
    expect(responses.map((response) => response.data?['data']), [
      'protected-ok',
      'protected-ok',
    ]);
  });

  test('refresh 失败后清理 token 并触发 unauthorized callback', () async {
    final secureStore = _MemorySecureTokenStore();
    final tokenStorage = TokenStorage(secureStore: secureStore);
    await tokenStorage.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    final adapter = _RefreshAdapter(refreshSucceeds: false);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'))
      ..httpClientAdapter = adapter;
    var unauthorizedCount = 0;

    final client = ApiClient(
      dio: dio,
      tokenStorage: tokenStorage,
      onUnauthorized: () => unauthorizedCount++,
    );

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(adapter.refreshCount, 1);
    expect(tokenStorage.accessToken, isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
    expect(unauthorizedCount, 1);
  });
}

class _AuthEndpointBoundaryAdapter implements HttpClientAdapter {
  int refreshEndpointCount = 0;
  final loginAuthorizationHeaders = <Object?>[];
  final refreshAuthorizationHeaders = <Object?>[];
  final logoutAuthorizationHeaders = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final authorization = options.headers['authorization'];

    if (options.path == '/auth/login') {
      loginAuthorizationHeaders.add(authorization);
      return _jsonResponse(
        statusCode: 401,
        body: <String, dynamic>{'code': 401, 'message': 'login failed'},
      );
    }

    if (options.path == '/auth/refresh') {
      refreshEndpointCount++;
      refreshAuthorizationHeaders.add(authorization);
      return _jsonResponse(
        statusCode: 401,
        body: <String, dynamic>{'code': 401, 'message': 'refresh failed'},
      );
    }

    if (options.path == '/auth/logout') {
      logoutAuthorizationHeaders.add(authorization);
      return _jsonResponse(
        statusCode: authorization == 'Bearer access-token' ? 200 : 401,
        body: <String, dynamic>{
          'code': authorization == 'Bearer access-token' ? 0 : 401,
          'message': authorization == 'Bearer access-token'
              ? 'ok'
              : 'unauthorized',
        },
      );
    }

    return _jsonResponse(
      statusCode: 404,
      body: <String, dynamic>{'code': 404, 'message': 'not found'},
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter({required this.refreshSucceeds});

  final bool refreshSucceeds;
  int refreshCount = 0;
  int protectedCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshCount++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (!refreshSucceeds) {
        return _jsonResponse(
          statusCode: 401,
          body: <String, dynamic>{'code': 401, 'message': 'refresh failed'},
        );
      }
      return _jsonResponse(
        statusCode: 200,
        body: <String, dynamic>{
          'code': 0,
          'message': 'ok',
          'data': <String, dynamic>{
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'user': <String, dynamic>{'id': '1', 'username': 'admin'},
            'roles': <String>['admin'],
            'permissions': <String>['system:user:list'],
            'menus': <Map<String, dynamic>>[],
          },
        },
      );
    }

    if (options.path == '/protected') {
      protectedCount++;
      if (options.headers[Headers.wwwAuthenticateHeader] != null) {
        throw StateError('测试不允许把 token 写入认证失败相关 header');
      }
      if (options.headers['authorization'] == 'Bearer new-access') {
        return _jsonResponse(
          statusCode: 200,
          body: <String, dynamic>{
            'code': 0,
            'message': 'ok',
            'data': 'protected-ok',
          },
        );
      }
      return _jsonResponse(
        statusCode: 401,
        body: <String, dynamic>{'code': 401, 'message': 'unauthorized'},
      );
    }

    return _jsonResponse(
      statusCode: 404,
      body: <String, dynamic>{'code': 404, 'message': 'not found'},
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse({
  required int statusCode,
  required Map<String, dynamic> body,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
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
