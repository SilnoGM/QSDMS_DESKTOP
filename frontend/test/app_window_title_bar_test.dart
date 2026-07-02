import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsdms_desktop_frontend/shared/widgets/window/app_window_title_bar.dart';

void main() {
  testWidgets('窗口栏使用固定高度并隐藏应用标题', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppWindowTitleBar(platform: AppWindowTitleBarPlatform.macos),
        ),
      ),
    );

    final titleBarSize = tester.getSize(find.byType(AppWindowTitleBar));

    expect(titleBarSize.height, AppWindowTitleBar.height);
    expect(find.text('QSDMS-千树数据管理系统'), findsNothing);
  });

  testWidgets('macOS 窗口栏左侧预留原生窗口按钮区域', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppWindowTitleBar(platform: AppWindowTitleBarPlatform.macos),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('macos-native-window-controls-space')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('macos-window-controls')), findsNothing);
    expect(find.byKey(const ValueKey('windows-window-controls')), findsNothing);
  });

  testWidgets('Windows 窗口栏右侧显示自定义窗口按钮并垂直居中', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppWindowTitleBar(platform: AppWindowTitleBarPlatform.windows),
        ),
      ),
    );

    final titleBarRect = tester.getRect(find.byType(AppWindowTitleBar));
    final controlsRect = tester.getRect(
      find.byKey(const ValueKey('windows-window-controls')),
    );

    expect(controlsRect.center.dy, titleBarRect.center.dy);
    expect(find.byKey(const ValueKey('macos-window-controls')), findsNothing);
    expect(
      find.byKey(const ValueKey('windows-window-controls')),
      findsOneWidget,
    );
    expect(find.byTooltip('最小化'), findsOneWidget);
    expect(find.byTooltip('最大化'), findsOneWidget);
    expect(find.byTooltip('关闭'), findsOneWidget);
  });
}
