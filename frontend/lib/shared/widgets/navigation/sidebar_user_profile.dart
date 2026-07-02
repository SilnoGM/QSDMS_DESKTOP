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
        return AlertDialog(
          title: Row(
            children: [
              _Avatar(user: user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user.name),
                    const SizedBox(height: 2),
                    Text(
                      user.role,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('账号：${user.account}'),
              const SizedBox(height: 6),
              Text('组织：${user.organization}'),
              const SizedBox(height: 6),
              Text(user.recentLoginText),
              const Divider(height: 24),
              const _DialogActionLabel(
                icon: Icons.person_outline,
                text: '个人信息',
              ),
              const SizedBox(height: 10),
              const _DialogActionLabel(
                icon: Icons.manage_accounts_outlined,
                text: '账号设置',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLogoutRequested?.call();
              },
              child: const Text(
                '退出登录',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(12),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: DecoratedBox(
        key: const ValueKey('sidebar-user-profile-capsule'),
        decoration: BoxDecoration(
          color: isExpanded ? AppColors.brandSubtle : AppColors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isExpanded
              ? Border.all(color: AppColors.brandSubtleBorder)
              : null,
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: -10,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 10 : 8,
            vertical: isExpanded ? 9 : 8,
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
                const _ArrowSurface(),
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

/// 右侧箭头的轻量承载面。
///
/// 箭头不直接裸露在文字后方，能让用户区更像一个明确可点击入口；同时保持
/// 低对比度，避免和侧边栏菜单选中态争抢注意力。
class _ArrowSurface extends StatelessWidget {
  const _ArrowSurface();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 28,
      child: DecoratedBox(
        key: const ValueKey('sidebar-user-profile-arrow-surface'),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.72),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.86)),
        ),
        child: const Center(
          child: Icon(
            Icons.keyboard_arrow_right,
            size: 17,
            color: AppColors.brandText,
          ),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brand, AppColors.link],
                ),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.92),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  user.avatarInitials,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              key: const ValueKey('sidebar-user-profile-status-dot'),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogActionLabel extends StatelessWidget {
  const _DialogActionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
