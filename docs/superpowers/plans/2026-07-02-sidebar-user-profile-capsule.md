# Sidebar User Profile Capsule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将侧边栏底部个人信息区优化为“轻快品牌胶囊”样式，并保持展开、折叠、弹窗和宽度动画稳定。

**Architecture:** 只改 `SidebarUserProfile` 的局部渲染结构，保留 `SidebarUserInfo` 数据模型和 `QsdmsSidebar` 组合方式。新增独立 widget 测试文件，避免混入当前 dirty 的 `app_shell_sidebar_test.dart`。

**Tech Stack:** Flutter Desktop, Material 3, `flutter_test`, existing `AppColors`, no new dependencies.

---

## File Structure

- Create: `frontend/test/sidebar_user_profile_capsule_test.dart`
  - 负责验证用户区展开态胶囊视觉、折叠态 Tooltip、在线状态点和弹窗入口不回归。
- Modify: `frontend/lib/shared/widgets/navigation/sidebar_user_profile.dart`
  - 负责用户区外观、头像样式、在线状态点、右侧圆形箭头和弹窗标题头像复用。

## Task 1: Failing Widget Tests

**Files:**
- Create: `frontend/test/sidebar_user_profile_capsule_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `frontend/test/sidebar_user_profile_capsule_test.dart`:

```dart
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
    expect(find.byKey(const ValueKey('sidebar-user-profile-status-dot')), findsOneWidget);
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
    expect(find.byKey(const ValueKey('sidebar-user-profile-status-dot')), findsOneWidget);
    expect(find.byKey(const ValueKey('sidebar-user-profile-arrow-surface')), findsNothing);
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
cd frontend && flutter test test/sidebar_user_profile_capsule_test.dart
```

Expected: FAIL because `sidebar-user-profile-capsule`, `sidebar-user-profile-status-dot`, and `sidebar-user-profile-arrow-surface` do not exist yet.

## Task 2: Minimal User Profile UI Implementation

**Files:**
- Modify: `frontend/lib/shared/widgets/navigation/sidebar_user_profile.dart`

- [ ] **Step 1: Implement the capsule surface, avatar status dot, and arrow surface**

Change `_UserProfileContent` so the `InkWell` child wraps a keyed `DecoratedBox`:

```dart
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
          ? const [
              BoxShadow(
                color: Color(0x141677FF),
                blurRadius: 16,
                spreadRadius: -10,
                offset: Offset(0, 10),
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
        mainAxisAlignment:
            isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
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
```

Add `_UserProfileText` and `_ArrowSurface` in the same file, and update `_Avatar` to render `sidebar-user-profile-status-dot`.

- [ ] **Step 2: Run focused tests**

Run:

```bash
cd frontend && flutter test test/sidebar_user_profile_capsule_test.dart
```

Expected: PASS.

## Task 3: Regression Verification and Commit

**Files:**
- Verify: `frontend/lib/shared/widgets/navigation/sidebar_user_profile.dart`
- Verify: `frontend/test/sidebar_user_profile_capsule_test.dart`

- [ ] **Step 1: Run sidebar regression tests**

Run:

```bash
cd frontend && flutter test test/sidebar_user_profile_capsule_test.dart test/app_shell_sidebar_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run static analysis**

Run:

```bash
cd frontend && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Commit only this implementation**

Run:

```bash
git add frontend/lib/shared/widgets/navigation/sidebar_user_profile.dart frontend/test/sidebar_user_profile_capsule_test.dart
git commit -m "feat: 优化侧边栏用户信息胶囊UI"
```

Expected: commit includes only the implementation file and the new test file.
