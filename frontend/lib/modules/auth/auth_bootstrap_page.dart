import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import 'auth_controller.dart';

/// 认证启动恢复页。
///
/// 冷启动时先进入这里再执行 `restoreSession()`，避免存在 refresh token 时先渲染
/// 登录表单、随后又跳转首页造成闪屏。页面只展示恢复状态，不读取或显示任何 token。
class AuthBootstrapPage extends StatefulWidget {
  const AuthBootstrapPage({super.key});

  @override
  State<AuthBootstrapPage> createState() => _AuthBootstrapPageState();
}

class _AuthBootstrapPageState extends State<AuthBootstrapPage> {
  late final AuthController _authController;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreAndRoute();
    });
  }

  Future<void> _restoreAndRoute() async {
    if (_started) {
      return;
    }
    _started = true;

    try {
      await _authController.restoreSession();
    } catch (_) {
      // 恢复失败只走未登录态，不把异常细节或 token 相关信息暴露给 UI。
    }

    if (!mounted) {
      return;
    }

    final targetRoute = _authController.isAuthenticated
        ? AppRoutes.home
        : AppRoutes.login;
    Get.offAllNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 20),
            Text(
              '正在恢复登录状态...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '请稍候',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
