import 'package:flutter/material.dart';

import '../../app/layout/app_shell.dart';
import '../../shared/widgets/layout/page_marker.dart';

/// 工作台页面。
///
/// 当前阶段先作为默认路由和侧边栏 `工作台` 菜单的落点，后续再替换为真实
/// 桌面端业务概览。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppShell(
        activeMenuId: 'dashboard',
        child: PageMarker(title: '工作台', description: '这里是工作台页面'),
      ),
    );
  }
}
