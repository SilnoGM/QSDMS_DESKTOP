import 'package:flutter/material.dart';

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

  bool get _isExpanded => displayMode == SidebarDisplayMode.expanded;

  @override
  Widget build(BuildContext context) {
    final isEnabled = item.enabled;
    final foregroundColor = isActive
        ? const Color(0xFF1F6FEB)
        : isEnabled
        ? const Color(0xFF667085)
        : const Color(0xFF98A2B3);
    final tooltipMessage = item.badge?.displayText == null
        ? item.label
        : '${item.label}，${item.badge!.displayText}';

    final content = AnimatedContainer(
      key: ValueKey('sidebar-menu-${item.id}'),
      duration: const Duration(milliseconds: 140),
      height: 46,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 0),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isExpanded
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
                      color: isActive
                          ? const Color(0xFF1F6FEB)
                          : const Color(0xFF344054),
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

    final tappable = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isEnabled && !isActive ? () => onSelected?.call(item) : null,
      child: content,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Tooltip(
        message: tooltipMessage,
        child: Semantics(
          button: true,
          selected: isActive,
          enabled: isEnabled,
          label: item.disabledReason == null
              ? item.label
              : '${item.label}，${item.disabledReason}',
          child: tappable,
        ),
      ),
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
