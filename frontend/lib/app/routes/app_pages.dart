import 'package:get/get.dart';

import '../../modules/home/home_binding.dart';
import '../../modules/home/home_page.dart';
import 'app_routes.dart';

/// GetX 页面路由表。
///
/// 每个业务页面通过自己的 Binding 注入依赖，确保路由、页面和 Controller
/// 的生命周期绑定在一起。
abstract final class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
  ];
}
