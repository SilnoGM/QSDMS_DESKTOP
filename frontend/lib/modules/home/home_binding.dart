import 'package:get/get.dart';

import 'home_controller.dart';

/// 首页依赖注入。
///
/// 首页 Controller 只在首页路由进入时创建，符合 GetX 页面级生命周期管理方式。
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
