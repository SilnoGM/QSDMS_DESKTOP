import 'package:flutter/material.dart';

import 'sidebar_models.dart';

/// 侧边栏底部通知公告卡片。
class SidebarNoticeCard extends StatelessWidget {
  const SidebarNoticeCard({required this.notice, this.onNoticeTap, super.key});

  final SidebarNoticeConfig notice;
  final ValueChanged<SidebarNoticeConfig>? onNoticeTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          key: const ValueKey('sidebar-notice-card'),
          borderRadius: BorderRadius.circular(8),
          onTap: notice.enabled ? () => onNoticeTap?.call(notice) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD6E6FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 22,
                  color: Color(0xFF1F6FEB),
                ),
                const SizedBox(height: 10),
                Text(
                  notice.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF175CD3),
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
                    color: Color(0xFF475467),
                    fontSize: 12,
                    height: 1.35,
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
