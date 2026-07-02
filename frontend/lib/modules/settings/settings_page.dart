import 'package:flutter/material.dart';

import '../../app/layout/app_shell.dart';
import '../../shared/widgets/layout/page_marker.dart';

/// 系统设置页面。
///
/// 首版仅作为侧边栏路由联动的目标页，后续再接入账号、权限、系统参数等
/// 配置能力。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppShell(
        activeMenuId: 'settings',
        child: PageMarker(title: '系统设置', description: '这里是系统设置页面'),
      ),
    );
  }
}
