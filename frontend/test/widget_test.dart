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

  testWidgets('Flutter 应用标题同步窗口标题文案', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    final app = tester.widget<GetMaterialApp>(find.byType(GetMaterialApp));

    expect(app.title, 'QSDMS-千树数据管理系统');
  });

  test('应用启动入口通过 window_manager 配置默认窗口', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mainDart = File('lib/main.dart').readAsStringSync();

    expect(pubspec, contains('window_manager:'));
    expect(
      mainDart,
      contains("import 'package:window_manager/window_manager.dart';"),
    );
    expect(mainDart, contains('await windowManager.ensureInitialized();'));
    expect(mainDart, contains('WindowOptions('));
    expect(mainDart, contains('size: Size(1280, 800)'));
    expect(mainDart, contains('minimumSize: Size(1280, 800)'));
    expect(mainDart, contains('center: true'));
    expect(mainDart, contains('backgroundColor: Color(0xFFFAFBFC)'));
    expect(mainDart, contains("title: 'QSDMS-千树数据管理系统'"));
    expect(mainDart, contains('windowManager.waitUntilReadyToShow'));
    expect(mainDart, contains('await windowManager.show();'));
    expect(mainDart, contains('await windowManager.focus();'));
  });

  test('桌面 runner 不保留旧的空标题配置', () {
    final macWindow = File('macos/Runner/MainFlutterWindow.swift')
        .readAsStringSync();
    final windowsMain = File('windows/runner/main.cpp').readAsStringSync();

    // 窗口标题现在由 window_manager 统一设置，runner 不再保留旧的空标题隐藏逻辑。
    expect(macWindow, isNot(contains('self.title = ""')));
    expect(macWindow, isNot(contains('self.titleVisibility = .hidden')));
    expect(windowsMain, isNot(contains('window.Create(L"", origin, size)')));
  });

  test('桌面 runner 默认尺寸与 window_manager 配置保持一致', () {
    final macXib = File('macos/Runner/Base.lproj/MainMenu.xib')
        .readAsStringSync();
    final windowsMain = File('windows/runner/main.cpp').readAsStringSync();

    final macRect = RegExp(
      r'<rect key="contentRect"[^>]*width="(\d+)" height="(\d+)"',
    ).firstMatch(macXib);
    final windowsSize = RegExp(
      r'Win32Window::Size size\((\d+),\s*(\d+)\);',
    ).firstMatch(windowsMain);

    expect(macRect, isNotNull);
    expect(windowsSize, isNotNull);

    final macWidth = int.parse(macRect!.group(1)!);
    final macHeight = int.parse(macRect.group(2)!);
    final windowsWidth = int.parse(windowsSize!.group(1)!);
    final windowsHeight = int.parse(windowsSize.group(2)!);

    // runner 初始值与 window_manager 配置一致，避免窗口显示前后尺寸跳变。
    expect(macWidth, 1280);
    expect(macHeight, 800);
    expect(windowsWidth, 1280);
    expect(windowsHeight, 800);
  });
}
