import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsdms_desktop_frontend/app/layout/app_shell.dart';
import 'package:qsdms_desktop_frontend/shared/widgets/navigation/sidebar_models.dart';
import 'package:qsdms_desktop_frontend/shared/widgets/navigation/qsdms_sidebar.dart';

void main() {
  const compactSize = Size(1280, 800);
  const standardSize = Size(1440, 900);

  Future<void> setDesktopSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    await setDesktopSize(tester, size);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppShell(
            activeMenuId: 'dashboard',
            child: SizedBox.expand(child: Text('内容区')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('1280 x 800 下主框架默认使用折叠侧边栏', (tester) async {
    await pumpShell(tester, compactSize);

    final sidebar = tester.widget<QsdmsSidebar>(find.byType(QsdmsSidebar));

    expect(sidebar.displayMode, SidebarDisplayMode.collapsed);
    expect(find.text('QSDMS'), findsNothing);
    expect(find.text('工作台'), findsNothing);
    expect(find.text('基础数据'), findsNothing);
    expect(find.text('系统设置'), findsNothing);
    expect(find.text('系统公告'), findsNothing);
    expect(find.text('SilnoGM'), findsNothing);
    expect(find.byTooltip('工作台'), findsOneWidget);
  });

  testWidgets('1440 x 900 下主框架默认使用展开侧边栏', (tester) async {
    await pumpShell(tester, standardSize);

    final sidebar = tester.widget<QsdmsSidebar>(find.byType(QsdmsSidebar));

    expect(sidebar.displayMode, SidebarDisplayMode.expanded);
    expect(find.text('QSDMS'), findsOneWidget);
    expect(find.text('工作台'), findsOneWidget);
    expect(find.text('基础数据'), findsOneWidget);
    expect(find.text('系统设置'), findsOneWidget);
    expect(find.text('系统公告'), findsOneWidget);
    expect(find.text('SilnoGM'), findsOneWidget);
  });

  testWidgets('展开状态不显示 Tooltip，折叠状态保留 Tooltip', (tester) async {
    Widget buildSidebar(SidebarDisplayMode displayMode) {
      return MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: displayMode,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSidebar(SidebarDisplayMode.expanded));
    await tester.pumpAndSettle();

    expect(find.byType(Tooltip), findsNothing);
    expect(find.byTooltip('工作台'), findsNothing);
    expect(find.byTooltip('QSDMS-千树数据管理系统'), findsNothing);
    expect(find.byTooltip('SilnoGM，系统管理员'), findsNothing);

    await tester.pumpWidget(buildSidebar(SidebarDisplayMode.collapsed));
    await tester.pumpAndSettle();

    expect(find.byTooltip('工作台'), findsOneWidget);
    expect(find.byTooltip('QSDMS-千树数据管理系统'), findsOneWidget);
    expect(find.byTooltip('SilnoGM，系统管理员'), findsOneWidget);
  });

  testWidgets('当前菜单由 activeItemId 驱动高亮且重复点击不触发回调', (tester) async {
    var selectedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: SidebarDisplayMode.expanded,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
            onMenuSelected: (_) => selectedCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dashboardItem = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('sidebar-menu-dashboard')),
    );
    final decoration = dashboardItem.decoration! as BoxDecoration;

    expect(decoration.color, const Color(0xFFEAF2FF));

    await tester.tap(find.text('工作台'));
    await tester.pumpAndSettle();

    expect(selectedCount, 0);
  });

  testWidgets('菜单项和用户信息区使用点击鼠标指针', (tester) async {
    const menuItems = [
      SidebarMenuItemConfig(
        id: 'dashboard',
        label: '工作台',
        routeName: '/',
        icon: Icons.dashboard_outlined,
      ),
      SidebarMenuItemConfig(
        id: 'clickable',
        label: '可点击菜单',
        routeName: '/clickable',
        icon: Icons.dataset_outlined,
      ),
      SidebarMenuItemConfig(
        id: 'disabled',
        label: '禁用菜单',
        routeName: '/disabled',
        icon: Icons.settings_outlined,
        enabled: false,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: menuItems,
            activeItemId: 'dashboard',
            displayMode: SidebarDisplayMode.expanded,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final clickableMenuInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.byKey(const ValueKey('sidebar-menu-clickable')),
        matching: find.byType(InkWell),
      ),
    );
    final disabledMenuInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.byKey(const ValueKey('sidebar-menu-disabled')),
        matching: find.byType(InkWell),
      ),
    );
    final userProfileInkWell = tester.widget<InkWell>(
      find.byKey(const ValueKey('sidebar-user-profile')),
    );

    expect(clickableMenuInkWell.mouseCursor, SystemMouseCursors.click);
    expect(disabledMenuInkWell.mouseCursor, SystemMouseCursors.basic);
    expect(userProfileInkWell.mouseCursor, SystemMouseCursors.click);
  });

  testWidgets('用户弹窗展示账户操作且退出登录触发回调', (tester) async {
    var logoutCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: SidebarDisplayMode.expanded,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
            onLogoutRequested: () => logoutCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sidebar-user-profile')));
    await tester.pumpAndSettle();

    expect(find.text('个人信息'), findsOneWidget);
    expect(find.text('账号设置'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();

    expect(logoutCount, 1);
  });

  testWidgets('用户区宽度动画中间帧不产生布局溢出', (tester) async {
    Widget buildSidebar(SidebarDisplayMode displayMode) {
      return MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: displayMode,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSidebar(SidebarDisplayMode.collapsed));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildSidebar(SidebarDisplayMode.expanded));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('公告卡片展开可见并触发回调，折叠状态隐藏', (tester) async {
    var noticeTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: SidebarDisplayMode.expanded,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
            onNoticeTap: (_) => noticeTapCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('系统公告'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-notice-card')));
    await tester.pumpAndSettle();

    expect(noticeTapCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: SidebarDisplayMode.collapsed,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
            onNoticeTap: (_) => noticeTapCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('系统公告'), findsNothing);
    expect(find.byKey(const ValueKey('sidebar-notice-card')), findsNothing);
  });

  testWidgets('公告卡片展示传入的标题和说明', (tester) async {
    const notice = SidebarNoticeConfig(
      title: '维护通知',
      description: '今晚 22:00 进行桌面端维护',
      url: 'https://example.com/maintenance',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: SidebarDisplayMode.expanded,
            user: QsdmsSidebarDefaults.user,
            notice: notice,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('维护通知'), findsOneWidget);
    expect(find.text('今晚 22:00 进行桌面端维护'), findsOneWidget);
  });

  testWidgets('公告卡片展开状态撑满侧边栏可用宽度', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QsdmsSidebar(
            items: QsdmsSidebarDefaults.menuItems,
            activeItemId: 'dashboard',
            displayMode: SidebarDisplayMode.expanded,
            user: QsdmsSidebarDefaults.user,
            notice: QsdmsSidebarDefaults.notice,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final noticeCardSize = tester.getSize(
      find.byKey(const ValueKey('sidebar-notice-card')),
    );

    expect(noticeCardSize.width, greaterThanOrEqualTo(223));
  });
}
