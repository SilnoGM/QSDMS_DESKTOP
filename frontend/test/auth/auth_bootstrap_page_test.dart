import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qsdms_desktop_frontend/app/bindings/initial_binding.dart';
import 'package:qsdms_desktop_frontend/app/qsdms_app.dart';
import 'package:qsdms_desktop_frontend/app/routes/app_routes.dart';
import 'package:qsdms_desktop_frontend/modules/auth/auth_controller.dart';
import 'package:qsdms_desktop_frontend/modules/auth/repositories/auth_repository.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/preference_storage.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(Get.reset);

  testWidgets('应用冷启动恢复会话时先显示恢复页而不是登录表单', (tester) async {
    final binding = _RestoringAuthBinding();

    await tester.pumpWidget(QsdmsApp(initialBinding: binding));
    await tester.pump();

    expect(find.text('正在恢复登录状态...'), findsOneWidget);
    expect(find.text('登录系统'), findsNothing);

    binding.controller.completeRestore();
    await tester.pumpAndSettle();

    expect(binding.controller.restoreCallCount, 1);
    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('当前页面：工作台'), findsOneWidget);
  });
}

class _RestoringAuthBinding extends InitialBinding {
  late final _RestoringAuthController controller;

  @override
  void dependencies() {
    final tokenStorage = TokenStorage(secureStore: _MemorySecureTokenStore());
    final repository = _FakeAuthRepository();
    controller = _RestoringAuthController(
      repository: repository,
      tokenStorage: tokenStorage,
      preferenceStorage: PreferenceStorage(),
    );

    Get.put<TokenStorage>(tokenStorage, permanent: true);
    Get.put<ApiClient>(
      ApiClient(dio: Dio(), tokenStorage: tokenStorage),
      permanent: true,
    );
    Get.put<AuthRepository>(repository, permanent: true);
    Get.put<AuthController>(controller, permanent: true);
  }
}

class _RestoringAuthController extends AuthController {
  _RestoringAuthController({
    required super.repository,
    required super.tokenStorage,
    required super.preferenceStorage,
  });

  final Completer<void> _restoreCompleter = Completer<void>();
  var _authenticated = false;
  var restoreCallCount = 0;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<void> restoreSession() async {
    restoreCallCount++;
    await _restoreCompleter.future;
    _authenticated = true;
  }

  void completeRestore() {
    _restoreCompleter.complete();
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiClient: ApiClient(
          dio: Dio(),
          tokenStorage: TokenStorage(secureStore: _MemorySecureTokenStore()),
        ),
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
