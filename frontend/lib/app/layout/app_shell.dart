import 'package:flutter/material.dart';

import '../../shared/widgets/navigation/qsdms_sidebar.dart';
import '../../shared/widgets/navigation/sidebar_models.dart';
import 'app_breakpoints.dart';
import 'app_layout_mode.dart';

/// 应用主框架。
///
/// `AppShell` 只负责组合侧边栏和内容区，不承载业务页面逻辑。侧边栏的
/// 展开 / 折叠由统一断点决定，内容区始终通过 `Expanded` 获取剩余空间。
class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    this.activeMenuId = 'dashboard',
    this.onMenuSelected,
    this.onLogoutRequested,
    this.onNoticeTap,
    super.key,
  });

  final Widget child;
  final String activeMenuId;
  final ValueChanged<SidebarMenuItemConfig>? onMenuSelected;
  final VoidCallback? onLogoutRequested;
  final ValueChanged<SidebarNoticeConfig>? onNoticeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutMode = AppBreakpoints.resolve(constraints.maxWidth);
        final sidebarMode = layoutMode == AppLayoutMode.compactDesktop
            ? SidebarDisplayMode.collapsed
            : SidebarDisplayMode.expanded;

        return Row(
          children: [
            QsdmsSidebar(
              items: QsdmsSidebarDefaults.menuItems,
              activeItemId: activeMenuId,
              displayMode: sidebarMode,
              user: QsdmsSidebarDefaults.user,
              notice: QsdmsSidebarDefaults.notice,
              onMenuSelected: onMenuSelected,
              onLogoutRequested: onLogoutRequested,
              onNoticeTap: onNoticeTap,
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFF6F8FA)),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
