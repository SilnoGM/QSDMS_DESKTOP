import 'package:get/get.dart';

import '../../shared/services/api_client.dart';

/// 应用级依赖注入。
///
/// 这里只注册跨模块共享的基础服务；页面级 Controller 由各业务模块自己的
/// Binding 注册，避免全局依赖过早膨胀。
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
  }
}
