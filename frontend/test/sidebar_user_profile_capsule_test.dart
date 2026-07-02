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

  testWidgets('用户弹窗使用白色背景关闭按钮和底部双实心按钮', (tester) async {
    await tester.pumpWidget(buildProfile(SidebarDisplayMode.expanded));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sidebar-user-profile')));
    await tester.pumpAndSettle();

    final dialogSurface = tester.widget<Dialog>(
      find.byKey(const ValueKey('sidebar-user-profile-dialog')),
    );
    final editButton = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar-user-profile-edit-button')),
        matching: find.byType(ElevatedButton),
      ),
    );
    final logoutButton = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar-user-profile-logout-button')),
        matching: find.byType(ElevatedButton),
      ),
    );

    expect(dialogSurface.backgroundColor, AppColors.white);
    expect(
      find.byKey(const ValueKey('sidebar-user-profile-dialog-close')),
      findsOneWidget,
    );
    expect(find.text('修改个人信息'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
    expect(editButton.style?.backgroundColor?.resolve({}), AppColors.brand);
    expect(logoutButton.style?.backgroundColor?.resolve({}), AppColors.error);

    await tester.tap(
      find.byKey(const ValueKey('sidebar-user-profile-dialog-close')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sidebar-user-profile-dialog')),
      findsNothing,
    );
  });

  testWidgets('用户弹窗底部按钮点击只打印日志', (tester) async {
    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      logs.add(message ?? '');
    };

    try {
      await tester.pumpWidget(buildProfile(SidebarDisplayMode.expanded));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('sidebar-user-profile')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('sidebar-user-profile-edit-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('sidebar-user-profile-logout-button')),
      );
      await tester.pumpAndSettle();
    } finally {
      debugPrint = originalDebugPrint;
    }

    expect(logs, contains('SidebarUserProfile: 修改个人信息'));
    expect(logs, contains('SidebarUserProfile: 退出登录'));
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
