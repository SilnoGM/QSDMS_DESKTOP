import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/app_colors.dart';
import 'sidebar_models.dart';

/// 侧边栏单个菜单项。
class SidebarMenuItem extends StatelessWidget {
  const SidebarMenuItem({
    required this.item,
    required this.isActive,
    required this.displayMode,
    this.onSelected,
    super.key,
  });

  final SidebarMenuItemConfig item;
  final bool isActive;
  final SidebarDisplayMode displayMode;
  final ValueChanged<SidebarMenuItemConfig>? onSelected;

  /// 菜单项主体高度。
  static const height = 46.0;

  /// 菜单项垂直外边距。
  static const verticalPadding = 3.0;

  /// 菜单项水平外边距。
  static const horizontalPadding = 12.0;

  /// 菜单项占用的完整垂直空间。
  static const outerHeight = height + verticalPadding * 2;

  bool get _isExpanded => displayMode == SidebarDisplayMode.expanded;

  @override
  Widget build(BuildContext context) {
    final isEnabled = item.enabled;
    final foregroundColor = isActive
        ? AppColors.brand
        : isEnabled
        ? AppColors.textSecondary
        : AppColors.textTertiary;
    final tooltipMessage = item.badge?.displayText == null
        ? item.label
        : '${item.label}，${item.badge!.displayText}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowExpandedContent =
            _isExpanded && constraints.maxWidth >= 160;

        return _SidebarMenuItemContent(
          item: item,
          isActive: isActive,
          isEnabled: isEnabled,
          showExpandedContent: canShowExpandedContent,
          showTooltip: !_isExpanded,
          foregroundColor: foregroundColor,
          tooltipMessage: tooltipMessage,
          onSelected: onSelected,
        );
      },
    );
  }
}

class _SidebarMenuItemContent extends StatelessWidget {
  const _SidebarMenuItemContent({
    required this.item,
    required this.isActive,
    required this.isEnabled,
    required this.showExpandedContent,
    required this.showTooltip,
    required this.foregroundColor,
    required this.tooltipMessage,
    this.onSelected,
  });

  final SidebarMenuItemConfig item;
  final bool isActive;
  final bool isEnabled;
  final bool showExpandedContent;
  final bool showTooltip;
  final Color foregroundColor;
  final String tooltipMessage;
  final ValueChanged<SidebarMenuItemConfig>? onSelected;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      key: ValueKey('sidebar-menu-${item.id}'),
      duration: const Duration(milliseconds: 140),
      height: SidebarMenuItem.height,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: showExpandedContent ? 12 : 0),
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: showExpandedContent
          ? Row(
              children: [
                Icon(item.icon, size: 21, color: foregroundColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? AppColors.brand : AppColors.textBody,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.badge?.displayText != null)
                  _SidebarBadge(badge: item.badge!),
              ],
            )
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, size: 21, color: foregroundColor),
                if (item.badge != null)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: _SidebarBadgeDot(color: item.badge!.color),
                  ),
              ],
            ),
    );

    // 菜单项自身只做轻微缩放和上浮，选中背景滑动由父级侧边栏统一处理。
    final animatedContent = content
        .animate(
          key: ValueKey('sidebar-menu-motion-${item.id}'),
          target: isActive ? 1 : 0,
        )
        .scaleXY(
          begin: 1,
          end: 1.018,
          duration: 180.ms,
          curve: Curves.easeOutCubic,
        )
        .moveY(
          begin: 0,
          end: -0.5,
          duration: 180.ms,
          curve: Curves.easeOutCubic,
        );

    final tappable = InkWell(
      borderRadius: BorderRadius.circular(8),
      mouseCursor: isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onTap: isEnabled && !isActive ? () => onSelected?.call(item) : null,
      child: animatedContent,
    );

    final semanticItem = Semantics(
      button: true,
      selected: isActive,
      enabled: isEnabled,
      label: item.disabledReason == null
          ? item.label
          : '${item.label}，${item.disabledReason}',
      child: tappable,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SidebarMenuItem.horizontalPadding,
        vertical: SidebarMenuItem.verticalPadding,
      ),
      child: showTooltip
          ? Tooltip(message: tooltipMessage, child: semanticItem)
          : semanticItem,
    );
  }
}

class _SidebarBadge extends StatelessWidget {
  const _SidebarBadge({required this.badge});

  final SidebarBadgeConfig badge;

  @override
  Widget build(BuildContext context) {
    final text = badge.displayText;
    if (text == null) {
      return _SidebarBadgeDot(color: badge.color);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: badge.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SidebarBadgeDot extends StatelessWidget {
  const _SidebarBadgeDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
