import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

/// QSDMS 桌面端应用入口。
///
/// 这里统一挂载 GetX 的路由、依赖注入和主题配置，避免业务页面直接关心
/// Flutter 根应用的启动细节。
class QsdmsApp extends StatelessWidget {
  const QsdmsApp({
    this.initialBinding,
    this.initialRoute = AppRoutes.home,
    super.key,
  });

  final Bindings? initialBinding;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '千树DMS',
      debugShowCheckedModeBanner: false,
      initialBinding: initialBinding ?? InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: AppTheme.light,
      // 桌面端侧边栏切换属于主框架内部导航，不应让整页参与滑入动画。
      defaultTransition: Transition.noTransition,
      transitionDuration: Duration.zero,
    );
  }
}
