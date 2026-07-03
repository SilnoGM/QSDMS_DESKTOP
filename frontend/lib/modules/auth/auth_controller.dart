import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import 'models/auth_session.dart';
import 'repositories/auth_repository.dart';
import 'storage/preference_storage.dart';
import 'storage/token_storage.dart';

/// 全局认证状态控制器。
///
/// Controller 只暴露认证状态、权限判断和登录/退出流程；页面不直接读写 token，
/// 避免敏感凭证在 UI 层扩散。
class AuthController extends GetxController {
  AuthController({
    required this.repository,
    required this.tokenStorage,
    required this.preferenceStorage,
  });

  final AuthRepository repository;
  final TokenStorage tokenStorage;
  final PreferenceStorage preferenceStorage;

  final session = Rxn<AuthSession>();
  final rememberLogin = false.obs;
  final lastUsername = ''.obs;
  final isLoading = false.obs;
  final isRestoring = false.obs;
  final errorMessage = ''.obs;

  bool _restoreAttempted = false;

  bool get isAuthenticated {
    return session.value != null && tokenStorage.accessToken != null;
  }

  Set<String> get permissions {
    return Set<String>.unmodifiable(
      session.value?.permissions ?? const <String>{},
    );
  }

  @override
  void onInit() {
    super.onInit();
    loadRememberedLogin();
  }

  @override
  void onReady() {
    super.onReady();
    restoreSession();
  }

  Future<void> loadRememberedLogin() async {
    final remembered = await preferenceStorage.readRememberLogin();
    rememberLogin.value = remembered;
    lastUsername.value = remembered
        ? await preferenceStorage.readLastUsername() ?? ''
        : '';
  }

  Future<bool> login({
    required String username,
    required String password,
    required bool rememberLogin,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final nextSession = await repository.login(
        username: username,
        password: password,
      );
      await tokenStorage.saveTokens(
        accessToken: nextSession.accessToken,
        refreshToken: nextSession.refreshToken,
      );
      session.value = nextSession;
      await _saveRememberPreference(
        username: username,
        shouldRemember: rememberLogin,
      );
      return true;
    } catch (_) {
      errorMessage.value = '登录失败，请检查用户名或密码';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreSession() async {
    if (_restoreAttempted) {
      return;
    }
    _restoreAttempted = true;

    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    isRestoring.value = true;
    try {
      final nextSession = await repository.refreshSession(refreshToken);
      await tokenStorage.saveTokens(
        accessToken: nextSession.accessToken,
        refreshToken: nextSession.refreshToken,
      );
      session.value = nextSession;
    } catch (_) {
      await tokenStorage.clear();
      session.value = null;
    } finally {
      isRestoring.value = false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    try {
      await repository.logout(refreshToken);
    } finally {
      await tokenStorage.clear();
      session.value = null;
    }
  }

  Future<void> handleUnauthorized() async {
    await tokenStorage.clear();
    session.value = null;
    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void applyRefreshedSessionData(Map<String, dynamic> data) {
    session.value = AuthSession.fromResponseData(data);
  }

  bool can(String permission) => permissions.contains(permission);

  bool canAny(Iterable<String> targetPermissions) {
    return targetPermissions.any(permissions.contains);
  }

  bool canAll(Iterable<String> targetPermissions) {
    return targetPermissions.every(permissions.contains);
  }

  Future<void> _saveRememberPreference({
    required String username,
    required bool shouldRemember,
  }) async {
    rememberLogin.value = shouldRemember;
    if (shouldRemember) {
      await preferenceStorage.saveRememberedLogin(username: username);
      lastUsername.value = username;
      return;
    }

    await preferenceStorage.clearRememberedLogin();
    lastUsername.value = '';
  }
}
