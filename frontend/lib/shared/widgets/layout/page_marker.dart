import 'package:flutter/material.dart';

/// 业务页面占位标记。
///
/// 当前阶段只需要证明路由和侧边栏菜单已经联动，所以这里保持轻量的文字标记。
/// 后续真实业务页面落地时，可以直接替换调用方的 `child`，不影响主框架。
class PageMarker extends StatelessWidget {
  const PageMarker({required this.title, required this.description, super.key});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '当前页面：$title',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}
