import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:qsdms_desktop_frontend/app/qsdms_app.dart';
import 'package:qsdms_desktop_frontend/modules/home/home_controller.dart';

void main() {
  testWidgets('首页路由展示工作台页面标记', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('当前页面：工作台'), findsOneWidget);
    expect(find.text('这里是工作台页面'), findsOneWidget);
  });

  testWidgets('侧边栏菜单点击后切换到对应页面', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const QsdmsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('基础数据'));
    await tester.pumpAndSettle();

    expect(find.text('当前页面：基础数据'), findsOneWidget);
    expect(find.text('这里是基础数据页面'), findsOneWidget);

    await tester.tap(find.text('系统设置'));
    await tester.pumpAndSettle();

    expect(find.text('当前页面：系统设置'), findsOneWidget);
    expect(find.text('这里是系统设置页面'), findsOneWidget);

    await tester.tap(find.text('工作台'));
    await tester.pumpAndSettle();

    expect(find.text('当前页面：工作台'), findsOneWidget);
    expect(find.text('这里是工作台页面'), findsOneWidget);
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

  testWidgets('桌面端路由切换不使用页面滑入动画', (tester) async {
    await tester.pumpWidget(const QsdmsApp());

    final app = tester.widget<GetMaterialApp>(find.byType(GetMaterialApp));

    expect(app.defaultTransition, Transition.noTransition);
    expect(app.transitionDuration, Duration.zero);
  });

  test('应用启动入口通过 window_manager 配置默认窗口', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mainDart = File('lib/main.dart').readAsStringSync();

    expect(pubspec, contains('window_manager:'));
    expect(mainDart, contains("import 'app/theme/app_colors.dart';"));
    expect(
      mainDart,
      contains("import 'package:window_manager/window_manager.dart';"),
    );
    expect(mainDart, contains('await windowManager.ensureInitialized();'));
    expect(mainDart, contains('WindowOptions('));
    expect(mainDart, contains('size: const Size(1280, 800)'));
    expect(mainDart, contains('minimumSize: const Size(1280, 800)'));
    expect(mainDart, contains('center: true'));
    expect(mainDart, contains('backgroundColor: AppColors.windowBackground'));
    expect(mainDart, contains("title: 'QSDMS-千树数据管理系统'"));
    expect(mainDart, contains('titleBarStyle: TitleBarStyle.hidden'));
    expect(mainDart, contains('windowButtonVisibility: Platform.isMacOS'));
    expect(mainDart, contains('windowManager.waitUntilReadyToShow'));
    expect(mainDart, contains('await windowManager.show();'));
    expect(mainDart, contains('await windowManager.focus();'));
  });

  test('桌面 runner 不保留旧的空标题配置', () {
    final macWindow = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();
    final windowsMain = File('windows/runner/main.cpp').readAsStringSync();

    // 窗口标题现在由 window_manager 统一设置，runner 不再保留旧的空标题隐藏逻辑。
    expect(macWindow, isNot(contains('self.title = ""')));
    expect(macWindow, isNot(contains('self.titleVisibility = .hidden')));
    expect(windowsMain, isNot(contains('window.Create(L"", origin, size)')));
  });

  test('macOS runner 对原生窗口按钮做垂直居中校正', () {
    final macWindow = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(macWindow, contains('customTitleBarHeight: CGFloat = 40'));
    expect(macWindow, contains('centerTrafficLightButtons()'));
    expect(macWindow, contains('standardWindowButton(.closeButton)'));
    expect(macWindow, contains('standardWindowButton(.miniaturizeButton)'));
    expect(macWindow, contains('standardWindowButton(.zoomButton)'));
    expect(macWindow, contains('trafficLightButtonContainer'));
    expect(macWindow, contains('trafficLightButtonContainer.superview'));
    expect(macWindow, contains('trafficLightButtonContainer.setFrameOrigin'));
    expect(
      macWindow,
      contains(
        'trafficLightButtonContainer.bounds.height - closeButton.frame.height',
      ),
    );
    expect(macWindow, contains('closeButton.setFrameOrigin'));
    expect(macWindow, contains('minimizeButton.setFrameOrigin'));
    expect(macWindow, contains('zoomButton.setFrameOrigin'));
    expect(macWindow, contains('titleBarView.bounds.height'));
    expect(
      macWindow,
      contains('titleBarView.bounds.height - customTitleBarHeight'),
    );
    expect(
      macWindow,
      contains(
        'let titleBarBottomY = titleBarView.bounds.height - customTitleBarHeight',
      ),
    );
    expect(macWindow, contains('setFrameOrigin'));
    expect(macWindow, contains('NSWindow.didResizeNotification'));
    expect(macWindow, contains('DispatchQueue.main.async'));
  });

  test('桌面 runner 默认尺寸与 window_manager 配置保持一致', () {
    final macXib = File(
      'macos/Runner/Base.lproj/MainMenu.xib',
    ).readAsStringSync();
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

  test('Flutter 静态图片目录已注册到 pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('assets:'));
    expect(pubspec, contains('- assets/images/'));
  });
}
