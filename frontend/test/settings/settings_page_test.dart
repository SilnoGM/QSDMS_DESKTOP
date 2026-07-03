import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qsdms_desktop_frontend/modules/auth/auth_controller.dart';
import 'package:qsdms_desktop_frontend/modules/auth/models/auth_session.dart';
import 'package:qsdms_desktop_frontend/modules/auth/repositories/auth_repository.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/preference_storage.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/modules/settings/settings_page.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(Get.reset);

  testWidgets('有 system:*:list 权限时显示对应系统设置 Tab', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {
        'system:user:list',
        'system:role:list',
        'system:permission:list',
      },
    );

    expect(find.text('用户管理'), findsOneWidget);
    expect(find.text('角色管理'), findsOneWidget);
    expect(find.text('权限管理'), findsOneWidget);
  });

  testWidgets('没有任何系统设置 Tab 权限时显示无权限空状态', (tester) async {
    await _pumpSettingsPage(tester, permissions: const <String>{});

    expect(find.text('用户管理'), findsNothing);
    expect(find.text('角色管理'), findsNothing);
    expect(find.text('权限管理'), findsNothing);
    expect(find.text('暂无系统设置权限'), findsOneWidget);
  });

  testWidgets('缺少 system:user:create 时不显示创建用户按钮', (tester) async {
    await _pumpSettingsPage(tester, permissions: const {'system:user:list'});

    expect(find.text('用户管理'), findsOneWidget);
    expect(find.text('创建用户'), findsNothing);
  });

  testWidgets('拥有 system:user:create 时显示创建用户按钮', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:user:list', 'system:user:create'},
    );

    expect(find.text('用户管理'), findsOneWidget);
    expect(find.text('创建用户'), findsOneWidget);
  });

  testWidgets('只有 system:user:list 时隐藏用户行操作按钮', (tester) async {
    await _pumpSettingsPage(tester, permissions: const {'system:user:list'});

    expect(find.text('用户管理'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '编辑'), findsNothing);
    expect(find.widgetWithText(PopupMenuButton<String>, '状态'), findsNothing);
    expect(find.widgetWithText(TextButton, '重置密码'), findsNothing);
    expect(find.widgetWithText(TextButton, '分配角色'), findsNothing);
  });

  testWidgets('system:user:update 控制用户编辑按钮', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:user:list', 'system:user:update'},
    );

    expect(find.widgetWithText(TextButton, '编辑'), findsOneWidget);
    expect(find.widgetWithText(PopupMenuButton<String>, '状态'), findsNothing);
    expect(find.widgetWithText(TextButton, '重置密码'), findsNothing);
    expect(find.widgetWithText(TextButton, '分配角色'), findsNothing);
  });

  testWidgets('system:user:disable 控制用户状态按钮', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:user:list', 'system:user:disable'},
    );

    expect(find.widgetWithText(TextButton, '编辑'), findsNothing);
    expect(find.widgetWithText(PopupMenuButton<String>, '状态'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '重置密码'), findsNothing);
    expect(find.widgetWithText(TextButton, '分配角色'), findsNothing);
  });

  testWidgets('system:user:reset-password 控制重置密码按钮', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:user:list', 'system:user:reset-password'},
    );

    expect(find.widgetWithText(TextButton, '编辑'), findsNothing);
    expect(find.widgetWithText(PopupMenuButton<String>, '状态'), findsNothing);
    expect(find.widgetWithText(TextButton, '重置密码'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '分配角色'), findsNothing);
  });

  testWidgets('system:user:assign-roles 控制分配角色按钮', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:user:list', 'system:user:assign-roles'},
    );

    expect(find.widgetWithText(TextButton, '编辑'), findsNothing);
    expect(find.widgetWithText(PopupMenuButton<String>, '状态'), findsNothing);
    expect(find.widgetWithText(TextButton, '重置密码'), findsNothing);
    expect(find.widgetWithText(TextButton, '分配角色'), findsOneWidget);
  });

  testWidgets('只有 system:role:list 时隐藏角色管理操作按钮', (tester) async {
    await _pumpSettingsPage(tester, permissions: const {'system:role:list'});

    expect(find.text('角色管理'), findsOneWidget);
    expect(find.text('创建角色'), findsNothing);
    expect(find.widgetWithText(TextButton, '编辑'), findsNothing);
    expect(find.widgetWithText(TextButton, '停用'), findsNothing);
    expect(find.widgetWithText(TextButton, '分配权限'), findsNothing);
  });

  testWidgets('system:role:create 控制创建角色按钮', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:role:list', 'system:role:create'},
    );

    expect(find.text('创建角色'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '编辑'), findsNothing);
    expect(find.widgetWithText(TextButton, '停用'), findsNothing);
    expect(find.widgetWithText(TextButton, '分配权限'), findsNothing);
  });

  testWidgets('system:role:update 控制角色编辑并禁用系统角色停用', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:role:list', 'system:role:update'},
    );

    expect(find.widgetWithText(TextButton, '编辑'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '停用'), findsOneWidget);
    expect(_textButtonEnabled(tester, '停用'), isFalse);
    expect(find.widgetWithText(TextButton, '分配权限'), findsNothing);
  });

  testWidgets('system:role:assign-permissions 控制分配权限并禁用系统角色编辑', (tester) async {
    await _pumpSettingsPage(
      tester,
      permissions: const {'system:role:list', 'system:role:assign-permissions'},
    );

    expect(find.widgetWithText(TextButton, '编辑'), findsNothing);
    expect(find.widgetWithText(TextButton, '停用'), findsNothing);
    expect(find.widgetWithText(TextButton, '分配权限'), findsOneWidget);
    expect(_textButtonEnabled(tester, '分配权限'), isFalse);
  });
}

bool _textButtonEnabled(WidgetTester tester, String label) {
  final button = tester.widget<TextButton>(
    find.widgetWithText(TextButton, label),
  );
  return button.onPressed != null;
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  required Set<String> permissions,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final tokenStorage = TokenStorage(secureStore: _MemorySecureTokenStore());
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'))
    ..httpClientAdapter = _SettingsPageAdapter();
  final apiClient = ApiClient(dio: dio, tokenStorage: tokenStorage);
  final authRepository = _SettingsFakeAuthRepository(apiClient);
  final authController =
      AuthController(
          repository: authRepository,
          tokenStorage: tokenStorage,
          preferenceStorage: PreferenceStorage(),
        )
        ..session.value = AuthSessionSnapshot(
          user: const AuthUser(
            id: 'user-1',
            username: 'admin',
            displayName: '管理员',
            raw: <String, dynamic>{},
          ),
          roles: const {'系统管理员'},
          permissions: permissions,
          menus: const [
            {
              'key': 'system-settings',
              'title': '系统设置',
              'route': '/settings',
              'icon': 'Settings',
              'permissionCode': 'menu:settings',
            },
          ],
        );

  Get.put<ApiClient>(apiClient, permanent: true);
  Get.put<AuthController>(authController, permanent: true);

  await tester.pumpWidget(const GetMaterialApp(home: SettingsPage()));
  await tester.pumpAndSettle();
}

class _SettingsPageAdapter implements HttpClientAdapter {
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
              {'id': 1, 'code': 'ADMIN', 'name': '系统管理员'},
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
            'permissions': <Object?>[],
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
            'id': 1,
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

class _SettingsFakeAuthRepository extends AuthRepository {
  _SettingsFakeAuthRepository(ApiClient apiClient)
    : super(apiClient: apiClient);
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
