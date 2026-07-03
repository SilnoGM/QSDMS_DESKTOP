import 'package:flutter/material.dart';

import 'sidebar_models.dart';

/// 侧边栏底部通知公告卡片。
class SidebarNoticeCard extends StatefulWidget {
  const SidebarNoticeCard({required this.notice, this.onNoticeTap, super.key});

  final SidebarNoticeConfig notice;
  final ValueChanged<SidebarNoticeConfig>? onNoticeTap;

  @override
  State<SidebarNoticeCard> createState() => _SidebarNoticeCardState();
}

class _SidebarNoticeCardState extends State<SidebarNoticeCard> {
  bool _hasImageLoadError = false;

  @override
  void didUpdateWidget(SidebarNoticeCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.notice.imageAssetPath != widget.notice.imageAssetPath) {
      _hasImageLoadError = false;
    }
  }

  void _hideAfterImageLoadError() {
    if (_hasImageLoadError) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasImageLoadError) {
        return;
      }

      setState(() {
        _hasImageLoadError = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageAssetPath = widget.notice.imageAssetPath?.trim();
    if (imageAssetPath == null ||
        imageAssetPath.isEmpty ||
        _hasImageLoadError) {
      return const SizedBox.shrink();
    }

    final isInteractive = widget.notice.canOpen && widget.onNoticeTap != null;
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
            onTap: isInteractive
                ? () => widget.onNoticeTap!(widget.notice)
                : null,
            child: _NoticeImage(
              assetPath: imageAssetPath,
              semanticLabel: widget.notice.title,
              onLoadError: _hideAfterImageLoadError,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeImage extends StatelessWidget {
  const _NoticeImage({
    required this.assetPath,
    required this.semanticLabel,
    required this.onLoadError,
  });

  final String assetPath;
  final String semanticLabel;
  final VoidCallback onLoadError;

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
          onLoadError();
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
