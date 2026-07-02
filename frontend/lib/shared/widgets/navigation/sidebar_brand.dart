import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
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
/// 折叠态空间有限，继续保留当前 `Q` 图标，避免图片在窄栏中不可辨认。
class _CollapsedBrandLogo extends StatelessWidget {
  const _CollapsedBrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Q',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
