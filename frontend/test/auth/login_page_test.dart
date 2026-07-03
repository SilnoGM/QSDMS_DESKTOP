import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qsdms_desktop_frontend/modules/auth/auth_controller.dart';
import 'package:qsdms_desktop_frontend/modules/auth/login_page.dart';
import 'package:qsdms_desktop_frontend/modules/auth/models/auth_session.dart';
import 'package:qsdms_desktop_frontend/modules/auth/repositories/auth_repository.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/preference_storage.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{
      PreferenceStorage.rememberLoginKey: true,
      PreferenceStorage.lastUsernameKey: 'SilnoGM',
    });
  });

  tearDown(Get.reset);

  testWidgets('登录页默认填充 lastUsername 并联动记住登录 checkbox', (tester) async {
    final controller = AuthController(
      repository: _FakeAuthRepository(),
      tokenStorage: TokenStorage(secureStore: _MemorySecureTokenStore()),
      preferenceStorage: PreferenceStorage(),
    );
    await controller.loadRememberedLogin();
    Get.put<AuthController>(controller);

    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    final usernameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('login-username-field')),
    );
    final rememberCheckbox = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('login-remember-checkbox')),
    );

    expect(find.text('登录系统'), findsOneWidget);
    expect(usernameField.controller?.text, 'SilnoGM');
    expect(rememberCheckbox.value, isTrue);

    await tester.tap(find.byKey(const ValueKey('login-remember-checkbox')));
    await tester.pumpAndSettle();

    final unchecked = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('login-remember-checkbox')),
    );
    expect(unchecked.value, isFalse);
  });
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: ApiClient(
          dio: Dio(),
          tokenStorage: TokenStorage(secureStore: _MemorySecureTokenStore()),
        ),
      );

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    return const AuthSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: AuthUser(
        id: '1',
        username: 'admin',
        displayName: '管理员',
        raw: <String, dynamic>{},
      ),
      roles: {'admin'},
      permissions: {'system:user:list'},
      menus: <Map<String, dynamic>>[],
    );
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
