import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import 'auth_controller.dart';

/// 认证路由守卫。
///
/// 受保护页面只看 `AuthController` 的当前认证状态；如果应用刚启动且存在
/// refresh token，控制器会在登录页恢复会话，恢复成功后登录页再跳回首页。
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
      return const RouteSettings(name: AppRoutes.login);
    }

    if (!requiresAuth && authController?.isAuthenticated == true) {
      return const RouteSettings(name: AppRoutes.home);
    }

    return null;
  }
}
