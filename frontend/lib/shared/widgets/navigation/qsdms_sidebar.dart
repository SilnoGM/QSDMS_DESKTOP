import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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

  double _indicatorOffset(int activeIndex) {
    return SidebarMenuItem.verticalPadding +
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
              Positioned(
                top: QsdmsSidebar.menuVerticalPadding,
                bottom: QsdmsSidebar.menuVerticalPadding,
                left: SidebarMenuItem.horizontalPadding,
                right: SidebarMenuItem.horizontalPadding,
                child: IgnorePointer(
                  child: _SidebarSpringIndicator(
                    key: const ValueKey('sidebar-active-menu-spring-indicator'),
                    offsetY: _indicatorOffset(activeIndex),
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

/// 侧边栏菜单选中背景。
///
/// 这里不用隐式布局动画，而是用弹簧模拟驱动 `Transform.translate`。这样菜单切换时
/// 背景会有轻微惯性，同时 surface 自身始终保持明确宽高，避免背景被压缩到不可见。
class _SidebarSpringIndicator extends StatefulWidget {
  const _SidebarSpringIndicator({required this.offsetY, super.key});

  final double offsetY;

  @override
  State<_SidebarSpringIndicator> createState() =>
      _SidebarSpringIndicatorState();
}

class _SidebarSpringIndicatorState extends State<_SidebarSpringIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 25,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
      value: widget.offsetY,
    );
  }

  @override
  void didUpdateWidget(covariant _SidebarSpringIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.offsetY == widget.offsetY) {
      return;
    }

    // 保留当前速度进入下一段弹簧动画，连续快速切换菜单时会更自然。
    final velocity = _controller.velocity.isFinite ? _controller.velocity : 0.0;
    _controller.animateWith(
      SpringSimulation(_spring, _controller.value, widget.offsetY, velocity),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _controller.value),
          child: Align(alignment: Alignment.topCenter, child: child),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: SidebarMenuItem.height,
        child: DecoratedBox(
          key: const ValueKey('sidebar-active-menu-indicator-surface'),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.brandSelectedGradientStart,
                AppColors.brandSelectedGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(SidebarMenuItem.activeRadius),
            boxShadow: const [
              BoxShadow(
                color: AppColors.brandSelectedShadow,
                blurRadius: 20,
                spreadRadius: -7,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SidebarMenuItem.activeRadius),
            child: Stack(
              children: [
                Positioned(
                  top: -18,
                  right: 18,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: -24,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
