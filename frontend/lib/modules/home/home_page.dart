import 'package:flutter/material.dart';

import '../../app/layout/app_shell.dart';

/// QSDMS 桌面端首页。
///
/// 首页先接入主框架和侧边栏，内容区仍保持空白骨架。这样可以先验证桌面端
/// 导航、响应式断点和用户入口，再逐步接入真实业务页面。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppShell(activeMenuId: 'dashboard', child: SizedBox.expand()),
    );
  }
}
