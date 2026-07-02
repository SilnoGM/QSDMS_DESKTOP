import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// 侧边栏展示状态。
///
/// 展开状态展示图标、中文文案、徽标、公告卡片和用户信息；折叠状态只保留
/// 图标、激活态、徽标提示和头像，以便在最小桌面宽度下把空间让给内容区。
enum SidebarDisplayMode { expanded, collapsed }

/// 菜单徽标类型。
enum SidebarBadgeType { count, dot, label, severity }

/// 菜单徽标配置。
class SidebarBadgeConfig {
  const SidebarBadgeConfig({
    required this.type,
    this.count,
    this.label,
    this.color = AppColors.error,
  });

  final SidebarBadgeType type;
  final int? count;
  final String? label;
  final Color color;

  /// 展开状态下的徽标文本。
  String? get displayText {
    if (type == SidebarBadgeType.count) {
      final value = count ?? 0;
      if (value <= 0) {
        return null;
      }
      return value > 99 ? '99+' : '$value';
    }

    return label;
  }
}

/// 侧边栏菜单项配置。
class SidebarMenuItemConfig {
  const SidebarMenuItemConfig({
    required this.id,
    required this.label,
    required this.routeName,
    required this.icon,
    this.badge,
    this.permissionCode,
    this.enabled = true,
    this.disabledReason,
    this.children = const [],
  });

  final String id;
  final String label;
  final String routeName;
  final IconData icon;
  final SidebarBadgeConfig? badge;
  final String? permissionCode;
  final bool enabled;
  final String? disabledReason;
  final List<SidebarMenuItemConfig> children;
}

/// 当前登录用户在侧边栏展示所需的最小信息。
class SidebarUserInfo {
  const SidebarUserInfo({
    required this.name,
    required this.role,
    required this.account,
    this.organization = '千树运营中心',
    this.recentLoginText = '最近登录：当前会话',
    this.avatarInitials = 'S',
    this.isSignedIn = true,
  });

  final String name;
  final String role;
  final String account;
  final String organization;
  final String recentLoginText;
  final String avatarInitials;
  final bool isSignedIn;
}

/// 侧边栏通知公告卡片配置。
class SidebarNoticeConfig {
  const SidebarNoticeConfig({
    required this.title,
    required this.description,
    required this.url,
    this.enabled = true,
  });

  final String title;
  final String description;
  final String url;
  final bool enabled;
}
