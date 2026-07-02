import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:qsdms_desktop_frontend/app/qsdms_app.dart';
import 'package:qsdms_desktop_frontend/modules/home/home_controller.dart';

void main() {
  testWidgets('使用 GetX 启动中文桌面工作台首页', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.text('QSDMS 企业数据管理系统'), findsOneWidget);
    expect(find.text('订单处理工作台'), findsOneWidget);
    expect(find.text('订单管理'), findsOneWidget);
    expect(find.text('供应商管理'), findsOneWidget);
    expect(find.text('产品资料'), findsOneWidget);
    expect(find.text('仓储发运'), findsOneWidget);
  });

  testWidgets('首页状态由 GetxController 提供', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    final controller = Get.find<HomeController>();

    expect(controller.workspaceTitle.value, '订单处理工作台');
    expect(controller.modules.length, 4);
  });
}
