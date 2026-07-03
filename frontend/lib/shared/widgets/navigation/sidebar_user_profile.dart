import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'sidebar_models.dart';

/// 侧边栏底部用户入口。
class SidebarUserProfile extends StatelessWidget {
  const SidebarUserProfile({
    required this.user,
    required this.displayMode,
    this.onLogoutRequested,
    super.key,
  });

  final SidebarUserInfo user;
  final SidebarDisplayMode displayMode;
  final VoidCallback? onLogoutRequested;

  bool get _isExpanded => displayMode == SidebarDisplayMode.expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowExpandedContent =
            _isExpanded && constraints.maxWidth >= 160;

        return _UserProfileContent(
          user: user,
          isExpanded: canShowExpandedContent,
          onTap: () => _showUserDialog(context),
        );
      },
    );
  }

  void _showUserDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          key: const ValueKey('sidebar-user-profile-dialog'),
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            key: const ValueKey('sidebar-user-profile-dialog-panel'),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              key: const ValueKey('sidebar-user-profile-dialog-content'),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(user: user),
                      const SizedBox(width: 12),
                      Expanded(child: _DialogUserTitle(user: user)),
                      IconButton(
                        key: const ValueKey(
                          'sidebar-user-profile-dialog-close',
                        ),
                        tooltip: '关闭',
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      key: const ValueKey(
                        'sidebar-user-profile-dialog-info-content',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        children: [
                          _DialogInfoRow(label: '账号', value: user.account),
                          const SizedBox(height: 10),
                          _DialogInfoRow(label: '组织', value: user.organization),
                          const SizedBox(height: 10),
                          _DialogInfoRow(
                            label: '登录',
                            value: user.recentLoginText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogSolidButton(
                          key: const ValueKey(
                            'sidebar-user-profile-edit-button',
                          ),
                          text: '修改个人信息',
                          backgroundColor: AppColors.brand,
                          onPressed: () {
                            debugPrint('SidebarUserProfile: 修改个人信息');
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _DialogSolidButton(
                          key: const ValueKey(
                            'sidebar-user-profile-logout-button',
                          ),
                          text: '退出登录',
                          backgroundColor: AppColors.error,
                          onPressed: () {
                            Navigator.of(context).pop();
                            onLogoutRequested?.call();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UserProfileContent extends StatelessWidget {
  const _UserProfileContent({
    required this.user,
    required this.isExpanded,
    required this.onTap,
  });

  final SidebarUserInfo user;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = InkWell(
      key: const ValueKey('sidebar-user-profile'),
      borderRadius: BorderRadius.circular(18),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: DecoratedBox(
        key: const ValueKey('sidebar-user-profile-capsule'),
        decoration: BoxDecoration(
          color: isExpanded ? AppColors.white : AppColors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isExpanded ? Border.all(color: AppColors.border) : null,
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    spreadRadius: -12,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 9 : 8,
            vertical: isExpanded ? 8 : 8,
          ),
          child: Row(
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              _Avatar(user: user),
              if (isExpanded) ...[
                const SizedBox(width: 10),
                Expanded(child: _UserProfileText(user: user)),
                const SizedBox(width: 8),
                const _ActionIcon(),
              ],
            ],
          ),
        ),
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: profile,
    );

    if (isExpanded) {
      return content;
    }

    return Tooltip(message: '${user.name}，${user.role}', child: content);
  }
}

/// 用户区的姓名和角色文案。
///
/// 单独拆出来是为了让胶囊容器只负责布局和点击热区，文案自身继续保持
/// 单行截断，避免长用户名在侧边栏宽度动画期间挤压头像和箭头。
class _UserProfileText extends StatelessWidget {
  const _UserProfileText({required this.user});

  final SidebarUserInfo user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          user.role,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

/// 右侧账户操作图标。
///
/// 参考图使用的是轻量退出/账户操作图标。这里仍然只作为账户入口的视觉提示，
/// 真正退出登录继续留在弹窗动作里，避免用户误触整块区域就直接退出。
class _ActionIcon extends StatelessWidget {
  const _ActionIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 28,
      child: Center(
        child: Icon(
          key: ValueKey('sidebar-user-profile-action-icon'),
          Icons.logout_rounded,
          size: 19,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final SidebarUserInfo user;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 38,
      child: DecoratedBox(
        key: const ValueKey('sidebar-user-profile-avatar-tile'),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.96),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                user.avatarInitials,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 弹窗顶部用户标题。
///
/// 与侧边栏胶囊中的文字层级保持一致，但字号略放大，方便用户确认当前正在
/// 操作哪个账号。
class _DialogUserTitle extends StatelessWidget {
  const _DialogUserTitle({required this.user});

  final SidebarUserInfo user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          user.role,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

/// 弹窗账号信息行。
///
/// 使用固定宽度标签保证三行内容左边界稳定；值区域使用省略号处理，避免长
/// 组织名或登录说明撑破弹窗。
class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// 弹窗底部实心按钮。
///
/// 两个按钮共享高度、圆角和内边距，只通过颜色和文字区分操作语义。
class _DialogSolidButton extends StatelessWidget {
  const _DialogSolidButton({
    required this.text,
    required this.backgroundColor,
    required this.onPressed,
    super.key,
  });

  final String text;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
