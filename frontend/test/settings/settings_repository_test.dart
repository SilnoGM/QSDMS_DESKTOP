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

  test('createUser 使用 POST /users 并提交后端 DTO body', () async {
    final adapter = _CaptureWriteAdapter();
    final repository = _buildRepository(adapter);

    await repository.createUser(
      username: 'operator01',
      displayName: '操作员',
      password: 'Password123',
      roleIds: const [1, 2],
    );

    expect(adapter.single.method, 'POST');
    expect(adapter.single.path, '/users');
    expect(adapter.single.body, {
      'username': 'operator01',
      'displayName': '操作员',
      'password': 'Password123',
      'roleIds': [1, 2],
    });
  });

  test('updateUser 使用 PATCH /users/:id 并提交用户名和显示名', () async {
    final adapter = _CaptureWriteAdapter();
    final repository = _buildRepository(adapter);

    await repository.updateUser(
      id: 'user-1',
      username: 'admin2',
      displayName: '管理员2',
    );

    expect(adapter.single.method, 'PATCH');
    expect(adapter.single.path, '/users/user-1');
    expect(adapter.single.body, {'username': 'admin2', 'displayName': '管理员2'});
  });

  test('updateUserStatus 使用 PATCH /users/:id/status 并提交 status', () async {
    final adapter = _CaptureWriteAdapter();
    final repository = _buildRepository(adapter);

    await repository.updateUserStatus(id: 'user-1', status: 'DISABLED');

    expect(adapter.single.method, 'PATCH');
    expect(adapter.single.path, '/users/user-1/status');
    expect(adapter.single.body, {'status': 'DISABLED'});
  });

  test(
    'resetUserPassword 使用 POST /users/:id/reset-password 并提交 password',
    () async {
      final adapter = _CaptureWriteAdapter();
      final repository = _buildRepository(adapter);
      const password = 'new-password-123';

      await repository.resetUserPassword(id: 'user-1', password: password);

      expect(adapter.single.method, 'POST');
      expect(adapter.single.path, '/users/user-1/reset-password');
      expect(adapter.single.body.keys, unorderedEquals(['password']));
      expect(adapter.single.body['password'] == password, isTrue);
    },
  );

  test('assignUserRoles 使用 PUT /users/:id/roles 并提交 roleIds', () async {
    final adapter = _CaptureWriteAdapter();
    final repository = _buildRepository(adapter);

    await repository.assignUserRoles(id: 'user-1', roleIds: const [2, 3]);

    expect(adapter.single.method, 'PUT');
    expect(adapter.single.path, '/users/user-1/roles');
    expect(adapter.single.body, {
      'roleIds': [2, 3],
    });
  });

  test('createRole 使用 POST /roles 并提交后端 DTO body', () async {
    final adapter = _CaptureWriteAdapter();
    final repository = _buildRepository(adapter);

    await repository.createRole(
      code: 'OPS_MANAGER',
      name: '运营经理',
      description: '负责运营管理',
      isActive: true,
    );

    expect(adapter.single.method, 'POST');
    expect(adapter.single.path, '/roles');
    expect(adapter.single.body, {
      'code': 'OPS_MANAGER',
      'name': '运营经理',
      'description': '负责运营管理',
      'isActive': true,
    });
  });

  test('updateRole 使用 PATCH /roles/:id 并提交后端 DTO body', () async {
    final adapter = _CaptureWriteAdapter();
    final repository = _buildRepository(adapter);

    await repository.updateRole(
      id: 7,
      name: '运营主管',
      description: '负责运营复核',
      isActive: false,
    );

    expect(adapter.single.method, 'PATCH');
    expect(adapter.single.path, '/roles/7');
    expect(adapter.single.body, {
      'name': '运营主管',
      'description': '负责运营复核',
      'isActive': false,
    });
  });

  test(
    'assignRolePermissions 使用 PUT /roles/:id/permissions 并提交 permissionIds',
    () async {
      final adapter = _CaptureWriteAdapter();
      final repository = _buildRepository(adapter);

      await repository.assignRolePermissions(
        id: 7,
        permissionIds: const [10, 11],
      );

      expect(adapter.single.method, 'PUT');
      expect(adapter.single.path, '/roles/7/permissions');
      expect(adapter.single.body, {
        'permissionIds': [10, 11],
      });
    },
  );
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

class _CaptureWriteAdapter implements HttpClientAdapter {
  final requests = <_CapturedRequest>[];

  _CapturedRequest get single {
    expect(requests, hasLength(1));
    return requests.single;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _CapturedRequest(
        method: options.method,
        path: options.path,
        body: Map<String, dynamic>.from(options.data as Map),
      ),
    );

    return _jsonResponse({
      'code': 'WRITE_SUCCESS',
      'message': 'saved',
      'data': _writeResponseData(options.path),
    });
  }

  @override
  void close({bool force = false}) {}
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> body;
}

Map<String, dynamic> _writeResponseData(String path) {
  if (path.startsWith('/roles')) {
    return {
      'id': 7,
      'code': 'OPS_MANAGER',
      'name': '运营经理',
      'description': '负责运营管理',
      'isSystem': false,
      'isActive': true,
      'permissions': [
        {
          'id': 10,
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
    };
  }

  return {
    'id': 'user-1',
    'username': 'operator01',
    'displayName': '操作员',
    'status': 'ACTIVE',
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
  };
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
