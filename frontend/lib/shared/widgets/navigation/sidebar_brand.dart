import 'package:flutter/material.dart';

import 'sidebar_models.dart';

/// 侧边栏顶部品牌区。
class SidebarBrand extends StatelessWidget {
  const SidebarBrand({required this.displayMode, super.key});

  final SidebarDisplayMode displayMode;

  bool get _isExpanded => displayMode == SidebarDisplayMode.expanded;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1F6FEB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Q',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final logoWithOptionalTooltip = _isExpanded
        ? logo
        : Tooltip(message: 'QSDMS-千树数据管理系统', child: logo);

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: _isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            logoWithOptionalTooltip,
            if (_isExpanded) ...[
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'QSDMS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
