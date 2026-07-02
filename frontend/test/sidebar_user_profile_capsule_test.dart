import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qsdms_desktop_frontend/app/theme/app_colors.dart';
import 'package:qsdms_desktop_frontend/shared/widgets/navigation/sidebar_models.dart';
import 'package:qsdms_desktop_frontend/shared/widgets/navigation/sidebar_user_profile.dart';

void main() {
  Widget buildProfile(SidebarDisplayMode displayMode) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 240,
          child: _ProfileUnderTest(displayMode: displayMode),
        ),
      ),
    );
  }

  testWidgets('展开状态展示参考图风格白色账户胶囊', (tester) async {
    await tester.pumpWidget(buildProfile(SidebarDisplayMode.expanded));
    await tester.pumpAndSettle();

    final capsule = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('sidebar-user-profile-capsule')),
    );
    final decoration = capsule.decoration as BoxDecoration;
    final avatarTile = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('sidebar-user-profile-avatar-tile')),
    );
    final avatarDecoration = avatarTile.decoration as BoxDecoration;
    final actionIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('sidebar-user-profile-action-icon')),
    );

    expect(find.text('SilnoGM'), findsOneWidget);
    expect(find.text('系统管理员'), findsOneWidget);
    expect(decoration.color, AppColors.white);
    expect(decoration.border?.top.color, AppColors.border);
    expect(decoration.boxShadow, isNotEmpty);
    expect(avatarDecoration.color, AppColors.error.withValues(alpha: 0.34));
    expect(actionIcon.icon, Icons.logout_rounded);
    expect(actionIcon.color, AppColors.textTertiary);
    expect(
      find.byKey(const ValueKey('sidebar-user-profile-status-dot')),
      findsNothing,
    );
  });

  testWidgets('折叠状态只展示头像并保留 Tooltip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 72,
            child: SidebarUserProfile(
              user: SidebarUserInfo(
                name: 'SilnoGM',
                role: '系统管理员',
                account: 'silnogm',
              ),
              displayMode: SidebarDisplayMode.collapsed,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SilnoGM'), findsNothing);
    expect(find.text('系统管理员'), findsNothing);
    expect(find.byTooltip('SilnoGM，系统管理员'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sidebar-user-profile-avatar-tile')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-user-profile-status-dot')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-user-profile-action-icon')),
      findsNothing,
    );
  });

  testWidgets('点击用户区仍打开账户操作弹窗', (tester) async {
    await tester.pumpWidget(buildProfile(SidebarDisplayMode.expanded));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sidebar-user-profile')));
    await tester.pumpAndSettle();

    expect(find.text('个人信息'), findsOneWidget);
    expect(find.text('账号设置'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
  });
}

class _ProfileUnderTest extends StatelessWidget {
  const _ProfileUnderTest({required this.displayMode});

  final SidebarDisplayMode displayMode;

  @override
  Widget build(BuildContext context) {
    return SidebarUserProfile(
      user: const SidebarUserInfo(
        name: 'SilnoGM',
        role: '系统管理员',
        account: 'silnogm',
      ),
      displayMode: displayMode,
    );
  }
}
