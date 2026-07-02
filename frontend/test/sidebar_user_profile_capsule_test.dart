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

  testWidgets('展开状态展示轻快品牌胶囊用户区', (tester) async {
    await tester.pumpWidget(buildProfile(SidebarDisplayMode.expanded));
    await tester.pumpAndSettle();

    final capsule = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('sidebar-user-profile-capsule')),
    );
    final decoration = capsule.decoration as BoxDecoration;
    final arrowSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('sidebar-user-profile-arrow-surface')),
    );
    final arrowDecoration = arrowSurface.decoration as BoxDecoration;

    expect(find.text('SilnoGM'), findsOneWidget);
    expect(find.text('系统管理员'), findsOneWidget);
    expect(decoration.color, AppColors.brandSubtle);
    expect(decoration.border?.top.color, AppColors.brandSubtleBorder);
    expect(decoration.boxShadow, isNotEmpty);
    expect(arrowDecoration.shape, BoxShape.circle);
    expect(
      find.byKey(const ValueKey('sidebar-user-profile-status-dot')),
      findsOneWidget,
    );
  });

  testWidgets('折叠状态只展示头像和状态点并保留 Tooltip', (tester) async {
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
      find.byKey(const ValueKey('sidebar-user-profile-status-dot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-user-profile-arrow-surface')),
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
