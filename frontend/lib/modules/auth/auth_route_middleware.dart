import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import 'auth_controller.dart';

/// 认证路由守卫。
///
/// 受保护页面只看 `AuthController` 的当前认证状态；如果应用刚启动且还未恢复
/// refresh token，先进入启动恢复页，由恢复页决定去首页还是登录页。
class AuthRouteMiddleware extends GetMiddleware {
  AuthRouteMiddleware.protected() : requiresAuth = true;

  AuthRouteMiddleware.guest() : requiresAuth = false;

  final bool requiresAuth;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    if (requiresAuth && authController?.isAuthenticated != true) {
      return const RouteSettings(name: AppRoutes.authBootstrap);
    }

    if (!requiresAuth && authController?.isAuthenticated == true) {
      return const RouteSettings(name: AppRoutes.home);
    }

    return null;
  }
}
