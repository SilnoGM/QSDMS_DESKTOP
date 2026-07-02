import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'sidebar_brand.dart';
import 'sidebar_menu_item.dart';
import 'sidebar_models.dart';
import 'sidebar_notice_card.dart';
import 'sidebar_user_profile.dart';

/// QSDMS 桌面端侧边栏。
class QsdmsSidebar extends StatelessWidget {
  const QsdmsSidebar({
    required this.items,
    required this.activeItemId,
    required this.displayMode,
    required this.user,
    this.notice,
    this.onMenuSelected,
    this.onLogoutRequested,
    this.onNoticeTap,
    super.key,
  });

  static const expandedWidth = 240.0;
  static const collapsedWidth = 72.0;
  static const menuVerticalPadding = 8.0;

  final List<SidebarMenuItemConfig> items;
  final String activeItemId;
  final SidebarDisplayMode displayMode;
  final SidebarUserInfo user;
  final SidebarNoticeConfig? notice;
  final ValueChanged<SidebarMenuItemConfig>? onMenuSelected;
  final VoidCallback? onLogoutRequested;
  final ValueChanged<SidebarNoticeConfig>? onNoticeTap;

  bool get _isExpanded => displayMode == SidebarDisplayMode.expanded;

  @override
  Widget build(BuildContext context) {
    final width = _isExpanded ? expandedWidth : collapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SidebarBrand(displayMode: displayMode),
            Expanded(
              child: _SidebarMenuList(
                items: items,
                activeItemId: activeItemId,
                displayMode: displayMode,
                onMenuSelected: onMenuSelected,
              ),
            ),
            if (_isExpanded && notice != null)
              SidebarNoticeCard(notice: notice!, onNoticeTap: onNoticeTap),
            SidebarUserProfile(
              user: user,
              displayMode: displayMode,
              onLogoutRequested: onLogoutRequested,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarMenuList extends StatelessWidget {
  const _SidebarMenuList({
    required this.items,
    required this.activeItemId,
    required this.displayMode,
    this.onMenuSelected,
  });

  final List<SidebarMenuItemConfig> items;
  final String activeItemId;
  final SidebarDisplayMode displayMode;
  final ValueChanged<SidebarMenuItemConfig>? onMenuSelected;

  int get _activeIndex => items.indexWhere((item) => item.id == activeItemId);

  double get _menuHeight {
    return QsdmsSidebar.menuVerticalPadding * 2 +
        SidebarMenuItem.outerHeight * items.length;
  }

  double _indicatorTop(int activeIndex) {
    return QsdmsSidebar.menuVerticalPadding +
        SidebarMenuItem.verticalPadding +
        SidebarMenuItem.outerHeight * activeIndex;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex;

    return SingleChildScrollView(
      child: SizedBox(
        height: _menuHeight,
        child: Stack(
          children: [
            if (activeIndex >= 0)
              AnimatedPositioned(
                key: const ValueKey('sidebar-active-menu-indicator'),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                top: _indicatorTop(activeIndex),
                left: SidebarMenuItem.horizontalPadding,
                right: SidebarMenuItem.horizontalPadding,
                height: SidebarMenuItem.height,
                child: DecoratedBox(
                  key: const ValueKey('sidebar-active-menu-indicator-box'),
                  decoration: BoxDecoration(
                    color: AppColors.brandSelectedBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: QsdmsSidebar.menuVerticalPadding,
              ),
              child: Column(
                children: [
                  for (final item in items)
                    SidebarMenuItem(
                      item: item,
                      isActive: item.id == activeItemId,
                      displayMode: displayMode,
                      onSelected: onMenuSelected,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首版侧边栏静态数据。
///
/// 真实认证、权限、公告接口尚未接入，默认值只用于主框架首版展示和测试。
abstract final class QsdmsSidebarDefaults {
  static const menuItems = [
    SidebarMenuItemConfig(
      id: 'dashboard',
      label: '工作台',
      routeName: '/',
      icon: Icons.dashboard_outlined,
    ),
    SidebarMenuItemConfig(
      id: 'baseData',
      label: '基础数据',
      routeName: '/base-data',
      icon: Icons.dataset_outlined,
    ),
    SidebarMenuItemConfig(
      id: 'settings',
      label: '系统设置',
      routeName: '/settings',
      icon: Icons.settings_outlined,
    ),
  ];

  static const user = SidebarUserInfo(
    name: 'SilnoGM',
    role: '系统管理员',
    account: 'silnogm',
  );

  static const notice = SidebarNoticeConfig(
    title: '系统公告',
    description: '查看最新桌面端更新说明',
    url: 'https://example.com/qsdms/notice',
  );
}
