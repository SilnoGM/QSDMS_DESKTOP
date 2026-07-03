import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'sidebar_models.dart';

/// 侧边栏底部通知公告卡片。
class SidebarNoticeCard extends StatelessWidget {
  const SidebarNoticeCard({required this.notice, this.onNoticeTap, super.key});

  final SidebarNoticeConfig notice;
  final ValueChanged<SidebarNoticeConfig>? onNoticeTap;

  @override
  Widget build(BuildContext context) {
    final isInteractive = notice.canOpen && onNoticeTap != null;
    const borderRadius = BorderRadius.all(Radius.circular(8));

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: InkWell(
            key: const ValueKey('sidebar-notice-card'),
            borderRadius: borderRadius,
            mouseCursor: isInteractive
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onTap: isInteractive ? () => onNoticeTap!(notice) : null,
            child: notice.imageAssetPath == null
                ? _NoticeTextFallback(notice: notice)
                : _NoticeImage(
                    assetPath: notice.imageAssetPath!,
                    semanticLabel: notice.title,
                  ),
          ),
        ),
      ),
    );
  }
}

class _NoticeImage extends StatelessWidget {
  const _NoticeImage({required this.assetPath, required this.semanticLabel});

  final String assetPath;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 666 / 312,
      child: Image.asset(
        assetPath,
        key: const ValueKey('sidebar-notice-image'),
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        errorBuilder: (context, error, stackTrace) {
          return const _NoticeImagePlaceholder();
        },
      ),
    );
  }
}

class _NoticeImagePlaceholder extends StatelessWidget {
  const _NoticeImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.brandSubtle),
      child: Center(
        child: Icon(Icons.campaign_outlined, size: 24, color: AppColors.brand),
      ),
    );
  }
}

class _NoticeTextFallback extends StatelessWidget {
  const _NoticeTextFallback({required this.notice});

  final SidebarNoticeConfig notice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.campaign_outlined, size: 22, color: AppColors.brand),
        const SizedBox(height: 10),
        Text(
          notice.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.brandText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          notice.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
