import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:qsdms_desktop_frontend/app/qsdms_app.dart';
import 'package:qsdms_desktop_frontend/modules/home/home_controller.dart';

void main() {
  testWidgets('首页路由保持可访问但不显示原有内容', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // 首页当前按需求清空，只保留路由和页面骨架，避免旧工作台内容继续露出。
    expect(find.text('QSDMS 企业数据管理系统'), findsNothing);
    expect(find.text('订单处理工作台'), findsNothing);
    expect(find.text('订单管理'), findsNothing);
    expect(find.text('供应商管理'), findsNothing);
    expect(find.text('产品资料'), findsNothing);
    expect(find.text('仓储发运'), findsNothing);
  });

  testWidgets('首页依赖仍由 GetX 路由绑定注册', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    expect(Get.isRegistered<HomeController>(), isTrue);
  });
}
