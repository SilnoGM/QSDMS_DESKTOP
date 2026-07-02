import 'package:flutter/material.dart';

import '../../app/layout/app_shell.dart';
import '../../shared/widgets/layout/page_marker.dart';

/// 基础数据页面。
///
/// 首版仅作为侧边栏路由联动的目标页，后续再接入地区、供应商、产品等真实
/// 基础资料管理能力。
class BaseDataPage extends StatelessWidget {
  const BaseDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppShell(
        activeMenuId: 'baseData',
        child: PageMarker(title: '基础数据', description: '这里是基础数据页面'),
      ),
    );
  }
}
