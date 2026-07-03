import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsdms_desktop_frontend/modules/auth/repositories/auth_repository.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  test('login 接受后端 *_SUCCESS 统一响应码', () async {
    final repository = _buildRepository(_AuthRepositoryAdapter());

    final result = await repository.login(
      username: 'admin',
      password: 'admin',
    );

    expect(result.accessToken, 'access-token');
    expect(result.refreshToken, 'refresh-token');
    expect(result.snapshot.user.username, 'admin');
    expect(result.snapshot.roles, {'SUPER_ADMIN'});
    expect(result.snapshot.permissions, {'menu:dashboard'});
  });

  test('fetchSession 解析不含 token 的 session snapshot', () async {
    final repository = _buildRepository(_AuthRepositoryAdapter());

    final snapshot = await repository.fetchSession();

    expect(snapshot.user.username, 'admin');
    expect(snapshot.roles, {'admin'});
    expect(snapshot.permissions, {'system:user:list'});
    expect(snapshot.menus.single['name'], '工作台');
  });

  test('fetchPermissions 支持 data 直接返回权限列表', () async {
    final repository = _buildRepository(_AuthRepositoryAdapter());

    final permissions = await repository.fetchPermissions();

    expect(permissions, {'system:user:list', 'order:read'});
  });
}

AuthRepository _buildRepository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'))
    ..httpClientAdapter = adapter;
  return AuthRepository(
    apiClient: ApiClient(
      dio: dio,
      tokenStorage: TokenStorage(secureStore: _MemorySecureTokenStore()),
    ),
  );
}

class _AuthRepositoryAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/login') {
      return _jsonResponse(<String, dynamic>{
        'code': 'AUTH_LOGIN_SUCCESS',
        'message': 'login succeeded',
        'data': <String, dynamic>{
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'user': <String, dynamic>{'id': '1', 'username': 'admin'},
          'roles': <String>['SUPER_ADMIN'],
          'permissions': <String>['menu:dashboard'],
          'menus': <Map<String, dynamic>>[
            <String, dynamic>{'key': 'dashboard', 'title': '工作台'},
          ],
        },
      });
    }

    if (options.path == '/auth/session') {
      return _jsonResponse(<String, dynamic>{
        'code': 0,
        'message': 'ok',
        'data': <String, dynamic>{
          'user': <String, dynamic>{'id': '1', 'username': 'admin'},
          'roles': <String>['admin'],
          'permissions': <String>['system:user:list'],
          'menus': <Map<String, dynamic>>[
            <String, dynamic>{'name': '工作台'},
          ],
        },
      });
    }

    if (options.path == '/auth/permissions') {
      return _jsonResponse(<String, dynamic>{
        'code': 0,
        'message': 'ok',
        'data': <String>['system:user:list', 'order:read'],
      });
    }

    return _jsonResponse(<String, dynamic>{
      'code': 404,
      'message': 'not found',
    }, statusCode: 404);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
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
