import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_controller.dart';

/// QSDMS 桌面端首页。
///
/// 首屏直接呈现工作台，不做营销式落地页；布局优先服务内部运营人员的高频
/// 业务入口扫描和后续表格工作流扩展。
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('QSDMS 企业数据管理系统')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  controller.workspaceTitle.value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '面向订单、供应商、产品、仓储与发运流程的桌面优先工作台。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Obx(
                  () => GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          mainAxisExtent: 132,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                    itemCount: controller.modules.length,
                    itemBuilder: (context, index) {
                      final module = controller.modules[index];
                      return _HomeModuleCard(module: module);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeModuleCard extends StatelessWidget {
  const _HomeModuleCard({required this.module});

  final HomeModule module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(module.description, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
