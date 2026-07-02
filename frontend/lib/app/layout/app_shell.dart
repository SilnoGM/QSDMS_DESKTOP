import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/navigation/qsdms_sidebar.dart';
import '../../shared/widgets/navigation/sidebar_models.dart';
import '../../shared/widgets/window/app_window_title_bar.dart';
import '../theme/app_colors.dart';
import 'app_breakpoints.dart';
import 'app_layout_mode.dart';

/// 应用主框架。
///
/// `AppShell` 负责组合侧边栏和内容区，并在未传入外部菜单回调时执行默认
/// GetX 路由切换。侧边栏的展开 / 折叠由统一断点决定，内容区始终通过
/// `Expanded` 获取剩余空间。
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

  void _handleMenuSelected(SidebarMenuItemConfig item) {
    if (onMenuSelected != null) {
      onMenuSelected!(item);
      return;
    }

    Get.offNamed(item.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutMode = AppBreakpoints.resolve(constraints.maxWidth);
        final sidebarMode = layoutMode == AppLayoutMode.compactDesktop
            ? SidebarDisplayMode.collapsed
            : SidebarDisplayMode.expanded;

        return Column(
          children: [
            const AppWindowTitleBar(),
            Expanded(
              child: Row(
                children: [
                  QsdmsSidebar(
                    items: QsdmsSidebarDefaults.menuItems,
                    activeItemId: activeMenuId,
                    displayMode: sidebarMode,
                    user: QsdmsSidebarDefaults.user,
                    notice: QsdmsSidebarDefaults.notice,
                    onMenuSelected: _handleMenuSelected,
                    onLogoutRequested: onLogoutRequested,
                    onNoticeTap: onNoticeTap,
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.pageBackground,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
