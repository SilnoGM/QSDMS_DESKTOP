import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/auth/auth_controller.dart';
import '../../modules/auth/models/auth_session.dart';
import '../../shared/services/external_url_opener.dart';
import '../../shared/widgets/navigation/qsdms_sidebar.dart';
import '../../shared/widgets/navigation/sidebar_models.dart';
import '../../shared/widgets/navigation/sidebar_selection_motion.dart';
import '../routes/app_routes.dart';
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

  void _handleMenuSelected({
    required SidebarMenuItemConfig item,
    required String resolvedActiveMenuId,
  }) {
    if (onMenuSelected != null) {
      onMenuSelected!(item);
      return;
    }

    SidebarSelectionMotion.begin(
      fromItemId: resolvedActiveMenuId,
      toItemId: item.id,
    );
    Get.offNamed(item.routeName);
  }

  void _handleNoticeTap(SidebarNoticeConfig notice) {
    if (onNoticeTap != null) {
      onNoticeTap!(notice);
      return;
    }

    unawaited(ExternalUrlOpener.open(notice.url));
  }

  Future<void> _handleLogoutRequested() async {
    if (onLogoutRequested != null) {
      onLogoutRequested!();
      return;
    }

    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().logout();
    }
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    if (authController == null) {
      return _AppShellFrame(
        activeMenuId: activeMenuId,
        menuItems: QsdmsSidebarDefaults.menuItems,
        user: QsdmsSidebarDefaults.user,
        onMenuSelected: (item, resolvedActiveMenuId) => _handleMenuSelected(
          item: item,
          resolvedActiveMenuId: resolvedActiveMenuId,
        ),
        onLogoutRequested: () => unawaited(_handleLogoutRequested()),
        onNoticeTap: _handleNoticeTap,
        child: child,
      );
    }

    return Obx(() {
      final session = authController.session.value;
      return _AppShellFrame(
        activeMenuId: activeMenuId,
        menuItems: _resolveMenuItems(session),
        user: _resolveUser(session),
        onMenuSelected: (item, resolvedActiveMenuId) => _handleMenuSelected(
          item: item,
          resolvedActiveMenuId: resolvedActiveMenuId,
        ),
        onLogoutRequested: () => unawaited(_handleLogoutRequested()),
        onNoticeTap: _handleNoticeTap,
        child: child,
      );
    });
  }

  List<SidebarMenuItemConfig> _resolveMenuItems(AuthSessionSnapshot? session) {
    final rawMenus = session?.menus ?? const <Map<String, dynamic>>[];
    if (rawMenus.isEmpty) {
      return QsdmsSidebarDefaults.menuItems;
    }

    final indexedMenus = rawMenus.indexed
        .map((entry) {
          final item = _menuItemFromRaw(entry.$2);
          return item == null ? null : (index: entry.$1, item: item);
        })
        .whereType<({int index, SidebarMenuItemConfig item})>()
        .toList();

    indexedMenus.sort((left, right) {
      final leftSort = _readInt(rawMenus[left.index], const ['sortOrder']);
      final rightSort = _readInt(rawMenus[right.index], const ['sortOrder']);
      if (leftSort == null && rightSort == null) {
        return left.index.compareTo(right.index);
      }
      if (leftSort == null) {
        return 1;
      }
      if (rightSort == null) {
        return -1;
      }
      return leftSort.compareTo(rightSort);
    });

    return indexedMenus.map((entry) => entry.item).toList(growable: false);
  }

  SidebarMenuItemConfig? _menuItemFromRaw(Map<String, dynamic> raw) {
    final routeName = _readString(raw, const ['route', 'routeName', 'path']);
    final label = _readString(raw, const ['title', 'label', 'name']);
    final id =
        _readString(raw, const ['key', 'id']) ??
        _legacyIdFromRoute(routeName) ??
        label;

    if (id == null || label == null || routeName == null) {
      return null;
    }

    return SidebarMenuItemConfig(
      id: id,
      label: label,
      routeName: routeName,
      icon: _iconFromName(_readString(raw, const ['icon'])),
      permissionCode: _readString(raw, const ['permissionCode']),
      children: _readChildMenus(raw['children']),
    );
  }

  List<SidebarMenuItemConfig> _readChildMenus(Object? value) {
    if (value is! Iterable) {
      return const <SidebarMenuItemConfig>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(_menuItemFromRaw)
        .whereType<SidebarMenuItemConfig>()
        .toList(growable: false);
  }

  IconData _iconFromName(String? iconName) {
    return switch (iconName) {
      'LayoutDashboard' => Icons.dashboard_outlined,
      'Database' => Icons.dataset_outlined,
      'Settings' => Icons.settings_outlined,
      _ => Icons.circle_outlined,
    };
  }

  SidebarUserInfo _resolveUser(AuthSessionSnapshot? session) {
    if (session == null) {
      return QsdmsSidebarDefaults.user;
    }

    final username = session.user.username.trim();
    final displayName = session.user.displayName.trim();
    final name = displayName.isNotEmpty
        ? displayName
        : username.isNotEmpty
        ? username
        : '未命名用户';
    final account = username.isNotEmpty ? username : name;

    return SidebarUserInfo(
      name: name,
      role: _roleSummary(
        session.roleLabels.isEmpty ? session.roles : session.roleLabels,
      ),
      account: account,
      avatarInitials: _avatarInitials(name, account),
    );
  }

  String _roleSummary(Iterable<String> roles) {
    final visibleRoles = roles.where((role) => role.trim().isNotEmpty).toList();
    if (visibleRoles.isEmpty) {
      return '未分配角色';
    }
    if (visibleRoles.length <= 2) {
      return visibleRoles.join('、');
    }
    return '${visibleRoles.take(2).join('、')} 等 ${visibleRoles.length} 个角色';
  }

  String _avatarInitials(String name, String account) {
    final source = name.trim().isNotEmpty ? name.trim() : account.trim();
    if (source.isEmpty) {
      return 'U';
    }
    return source.characters.first.toUpperCase();
  }
}

class _AppShellFrame extends StatelessWidget {
  const _AppShellFrame({
    required this.child,
    required this.activeMenuId,
    required this.menuItems,
    required this.user,
    required this.onMenuSelected,
    required this.onLogoutRequested,
    required this.onNoticeTap,
  });

  final Widget child;
  final String activeMenuId;
  final List<SidebarMenuItemConfig> menuItems;
  final SidebarUserInfo user;
  final void Function(SidebarMenuItemConfig item, String resolvedActiveMenuId)
  onMenuSelected;
  final VoidCallback onLogoutRequested;
  final ValueChanged<SidebarNoticeConfig> onNoticeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutMode = AppBreakpoints.resolve(constraints.maxWidth);
        final sidebarMode = layoutMode == AppLayoutMode.compactDesktop
            ? SidebarDisplayMode.collapsed
            : SidebarDisplayMode.expanded;
        final resolvedActiveMenuId = _resolveActiveMenuId(
          menuItems,
          activeMenuId,
        );

        return Column(
          children: [
            const AppWindowTitleBar(),
            Expanded(
              child: Row(
                children: [
                  QsdmsSidebar(
                    items: menuItems,
                    activeItemId: resolvedActiveMenuId,
                    displayMode: sidebarMode,
                    user: user,
                    notice: QsdmsSidebarDefaults.notice,
                    onMenuSelected: (item) =>
                        onMenuSelected(item, resolvedActiveMenuId),
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

  String _resolveActiveMenuId(
    List<SidebarMenuItemConfig> items,
    String requestedId,
  ) {
    if (items.any((item) => item.id == requestedId)) {
      return requestedId;
    }

    for (final candidate in _activeIdCandidates(requestedId)) {
      if (items.any((item) => item.id == candidate)) {
        return candidate;
      }
    }

    return requestedId;
  }

  Iterable<String> _activeIdCandidates(String requestedId) {
    return switch (requestedId) {
      'baseData' => const ['base-data'],
      'base-data' => const ['baseData'],
      'settings' => const ['system-settings'],
      'system-settings' => const ['settings'],
      _ => const <String>[],
    };
  }
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

int? _readInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
  }
  return null;
}

String? _legacyIdFromRoute(String? routeName) {
  return switch (routeName) {
    AppRoutes.home => 'dashboard',
    AppRoutes.baseData => 'base-data',
    AppRoutes.settings => 'system-settings',
    _ => null,
  };
}
