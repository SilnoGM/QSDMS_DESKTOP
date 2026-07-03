import 'package:get/get.dart';

import '../../modules/base_data/base_data_page.dart';
import '../../modules/auth/auth_route_middleware.dart';
import '../../modules/auth/login_page.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/home/home_page.dart';
import '../../modules/settings/settings_page.dart';
import 'app_routes.dart';

/// GetX 页面路由表。
///
/// 需要页面级依赖的业务页面通过自己的 Binding 注入依赖，确保路由、页面和
/// Controller 的生命周期绑定在一起。
abstract final class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthRouteMiddleware.protected()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      middlewares: [AuthRouteMiddleware.guest()],
    ),
    GetPage(
      name: AppRoutes.baseData,
      page: () => const BaseDataPage(),
      middlewares: [AuthRouteMiddleware.protected()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      middlewares: [AuthRouteMiddleware.protected()],
    ),
  ];
}
