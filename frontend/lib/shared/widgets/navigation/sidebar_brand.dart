import 'package:flutter/material.dart';

import 'sidebar_models.dart';

/// 侧边栏顶部品牌区。
class SidebarBrand extends StatelessWidget {
  const SidebarBrand({required this.displayMode, super.key});

  final SidebarDisplayMode displayMode;

  bool get _isExpanded => displayMode == SidebarDisplayMode.expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: _isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            _isExpanded
                ? const Expanded(child: _ExpandedBrandImage())
                : const Tooltip(
                    message: 'QSDMS-千树数据管理系统',
                    child: _CollapsedBrandLogo(),
                  ),
          ],
        ),
      ),
    );
  }
}

/// 侧边栏展开态品牌图。
///
/// 图片资源由 `pubspec.yaml` 统一注册。这里使用 `BoxFit.contain` 保持原图比例，
/// 避免不同分辨率下拉伸变形。
class _ExpandedBrandImage extends StatelessWidget {
  const _ExpandedBrandImage();

  static const assetPath = 'assets/images/QIANSHUDMS.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      key: const ValueKey('sidebar-brand-image'),
      height: 50,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      semanticLabel: '千树数据平台',
    );
  }
}

/// 侧边栏折叠态品牌图标。
///
/// 折叠态只展示独立的 `Q.png` 品牌图片，避免影响展开态完整品牌图。
class _CollapsedBrandLogo extends StatelessWidget {
  const _CollapsedBrandLogo();

  static const assetPath = 'assets/images/Q.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      key: const ValueKey('sidebar-brand-image'),
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      semanticLabel: 'QSDMS',
    );
  }
}
