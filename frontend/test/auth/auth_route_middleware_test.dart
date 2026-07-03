import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:qsdms_desktop_frontend/app/bindings/initial_binding.dart';
import 'package:qsdms_desktop_frontend/app/qsdms_app.dart';
import 'package:qsdms_desktop_frontend/app/routes/app_routes.dart';
import 'package:qsdms_desktop_frontend/modules/auth/auth_controller.dart';
import 'package:qsdms_desktop_frontend/modules/auth/models/auth_session.dart';
import 'package:qsdms_desktop_frontend/modules/auth/repositories/auth_repository.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/preference_storage.dart';
import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';
import 'package:qsdms_desktop_frontend/shared/services/api_client.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('未认证访问受保护页面跳转登录页', (tester) async {
    await tester.pumpWidget(
      QsdmsApp(initialBinding: _AuthTestBinding(isAuthenticated: false)),
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(find.text('登录系统'), findsOneWidget);
  });

  testWidgets('已认证访问登录页跳转首页', (tester) async {
    await tester.pumpWidget(
      QsdmsApp(
        initialRoute: AppRoutes.login,
        initialBinding: _AuthTestBinding(isAuthenticated: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('当前页面：工作台'), findsOneWidget);
  });
}

class _AuthTestBinding extends InitialBinding {
  _AuthTestBinding({required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  void dependencies() {
    final tokenStorage = TokenStorage(secureStore: _MemorySecureTokenStore());
    final repository = _FakeAuthRepository();
    final controller = _FakeAuthController(
      repository: repository,
      tokenStorage: tokenStorage,
      preferenceStorage: PreferenceStorage(),
      isAuthenticatedValue: isAuthenticated,
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

class _FakeAuthController extends AuthController {
  _FakeAuthController({
    required super.repository,
    required super.tokenStorage,
    required super.preferenceStorage,
    required this.isAuthenticatedValue,
  });

  final bool isAuthenticatedValue;

  @override
  bool get isAuthenticated => isAuthenticatedValue;
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
  Future<AuthSession> refreshSession(String refreshToken) async {
    throw StateError('route middleware tests should not refresh');
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
