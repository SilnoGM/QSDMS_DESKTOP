import 'dart:io';

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

  testWidgets('Flutter 应用标题不再显示窗口标题文案', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    final app = tester.widget<GetMaterialApp>(find.byType(GetMaterialApp));

    expect(app.title, isEmpty);
  });

  test('桌面 runner 不再写入可见窗口标题', () {
    final macWindow = File('macos/Runner/MainFlutterWindow.swift')
        .readAsStringSync();
    final windowsMain = File('windows/runner/main.cpp').readAsStringSync();

    // 原生桌面窗口标题需要显式置空，避免平台 runner 使用默认应用名展示标题栏文字。
    expect(macWindow, contains('self.title = ""'));
    expect(macWindow, contains('self.titleVisibility = .hidden'));
    expect(windowsMain, contains('window.Create(L"", origin, size)'));
    expect(windowsMain, isNot(contains('window.Create(L"qsdms_desktop_frontend"')));
  });
}
