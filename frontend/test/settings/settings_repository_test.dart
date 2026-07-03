import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/modules/settings/repositories/settings_repository.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  test('SettingsRepository 解析 users/roles/permissions 统一响应', () async {
    final repository = _buildRepository(_SettingsRepositoryAdapter());

    final users = await repository.fetchUsers();
    final roles = await repository.fetchRoles();
    final permissions = await repository.fetchPermissions();

    expect(users.single.username, 'admin');
    expect(users.single.displayName, '管理员');
    expect(users.single.roles.single.name, '系统管理员');

    expect(roles.single.code, 'ADMIN');
    expect(roles.single.permissions.single.code, 'system:user:list');

    expect(permissions.single.module, 'system');
    expect(permissions.single.type, 'ACTION');
  });
}

SettingsRepository _buildRepository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'))
    ..httpClientAdapter = adapter;
  return SettingsRepository(
    apiClient: ApiClient(
      dio: dio,
      tokenStorage: TokenStorage(secureStore: _MemorySecureTokenStore()),
    ),
  );
}

class _SettingsRepositoryAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/users') {
      return _jsonResponse({
        'code': 'USERS_LIST_SUCCESS',
        'message': 'users loaded',
        'data': [
          {
            'id': 'user-1',
            'username': 'admin',
            'status': 'ACTIVE',
            'profile': {'displayName': '管理员'},
            'roles': [
              {
                'id': 1,
                'code': 'ADMIN',
                'name': '系统管理员',
                'description': null,
                'isSystem': true,
                'isActive': true,
              },
            ],
          },
        ],
      });
    }

    if (options.path == '/roles') {
      return _jsonResponse({
        'code': 'ROLES_LIST_SUCCESS',
        'message': 'roles loaded',
        'data': [
          {
            'id': 1,
            'code': 'ADMIN',
            'name': '系统管理员',
            'description': null,
            'isSystem': true,
            'isActive': true,
            'permissions': [
              {
                'id': 11,
                'code': 'system:user:list',
                'name': '用户列表',
                'type': 'ACTION',
                'module': 'system',
                'description': null,
                'sortOrder': 10,
                'isSystem': true,
                'isActive': true,
              },
            ],
          },
        ],
      });
    }

    if (options.path == '/permissions') {
      return _jsonResponse({
        'code': 'PERMISSIONS_LIST_SUCCESS',
        'message': 'permissions loaded',
        'data': [
          {
            'id': 11,
            'code': 'system:user:list',
            'name': '用户列表',
            'type': 'ACTION',
            'module': 'system',
            'description': null,
            'sortOrder': 10,
            'isSystem': true,
            'isActive': true,
          },
        ],
      });
    }

    return _jsonResponse({'code': 'NOT_FOUND', 'message': 'not found'});
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
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
