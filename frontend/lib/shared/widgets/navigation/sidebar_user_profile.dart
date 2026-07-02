import 'package:flutter/material.dart';

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
                        color: Color(0xFF667085),
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
                style: TextStyle(color: Color(0xFFD92D20)),
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
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            _Avatar(user: user),
            if (isExpanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_right,
                size: 18,
                color: Color(0xFF98A2B3),
              ),
            ],
          ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final SidebarUserInfo user;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF1F6FEB),
      child: Text(
        user.avatarInitials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
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
        Icon(icon, size: 18, color: const Color(0xFF667085)),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
