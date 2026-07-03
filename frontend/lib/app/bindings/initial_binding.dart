import 'package:get/get.dart';

import '../../modules/auth/auth_controller.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/auth/storage/preference_storage.dart';
import '../../modules/auth/storage/token_storage.dart';
import '../../shared/services/api_client.dart';

/// 应用级依赖注入。
///
/// 这里只注册跨模块共享的基础服务；认证属于全局基础能力，需要在路由守卫
/// 执行前可用，所以这里使用永久实例。
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TokenStorage>()) {
      Get.put<TokenStorage>(TokenStorage(), permanent: true);
    }
    if (!Get.isRegistered<PreferenceStorage>()) {
      Get.put<PreferenceStorage>(PreferenceStorage(), permanent: true);
    }
    if (!Get.isRegistered<ApiClient>()) {
      Get.put<ApiClient>(
        ApiClient(tokenStorage: Get.find<TokenStorage>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(
        AuthRepository(apiClient: Get.find<ApiClient>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<AuthController>()) {
      final authController = AuthController(
        repository: Get.find<AuthRepository>(),
        tokenStorage: Get.find<TokenStorage>(),
        preferenceStorage: Get.find<PreferenceStorage>(),
      );
      final apiClient = Get.find<ApiClient>();
      apiClient.onUnauthorized = authController.handleUnauthorized;
      apiClient.onRefreshData = authController.applyRefreshedSessionData;
      Get.put<AuthController>(authController, permanent: true);
    }
  }
}
