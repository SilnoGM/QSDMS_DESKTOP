# Sidebar User Dialog Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将侧边栏用户区点击后的弹窗优化为白色背景、适中内边距、右上角关闭按钮和底部双实心按钮的账号操作弹窗。

**Architecture:** 只修改 `SidebarUserProfile` 内部弹窗渲染，不改 `SidebarUserInfo`、`QsdmsSidebar` 或认证流程。按钮点击临时使用 `debugPrint` 打印日志，不触发真实编辑或退出。

**Tech Stack:** Flutter Desktop, Material 3, `flutter_test`, existing `AppColors`, no new dependencies.

---

## File Structure

- Modify: `frontend/lib/shared/widgets/navigation/sidebar_user_profile.dart`
  - 将默认 `AlertDialog` 替换为自定义白色 `Dialog` 内容。
  - 增加右上角关闭按钮、信息行、底部两个 `ElevatedButton` 实心按钮。
  - 按钮点击只打印 `debugPrint` 日志。
- Modify: `frontend/test/sidebar_user_profile_capsule_test.dart`
  - 增加弹窗结构、关闭按钮和按钮日志测试。
- Modify: `frontend/test/app_shell_sidebar_test.dart`
  - 更新旧测试，退出按钮不再触发 `onLogoutRequested`，仅验证弹窗结构。
- Modify: `docs/custom_widget_design/Sidebar-侧边栏.md`
  - 同步弹窗内容和临时日志行为说明。

## Task 1: RED Tests

- [ ] **Step 1: Write failing dialog tests**

Update `frontend/test/sidebar_user_profile_capsule_test.dart`:

```dart
testWidgets('用户弹窗使用白色背景关闭按钮和底部双实心按钮', (tester) async {
  await tester.pumpWidget(buildProfile(SidebarDisplayMode.expanded));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('sidebar-user-profile')));
  await tester.pumpAndSettle();

  final dialogSurface = tester.widget<Dialog>(
    find.byKey(const ValueKey('sidebar-user-profile-dialog')),
  );
  final editButton = tester.widget<ElevatedButton>(
    find.byKey(const ValueKey('sidebar-user-profile-edit-button')),
  );
  final logoutButton = tester.widget<ElevatedButton>(
    find.byKey(const ValueKey('sidebar-user-profile-logout-button')),
  );

  expect(dialogSurface.backgroundColor, AppColors.white);
  expect(find.byKey(const ValueKey('sidebar-user-profile-dialog-close')), findsOneWidget);
  expect(find.text('修改个人信息'), findsOneWidget);
  expect(find.text('退出登录'), findsOneWidget);
  expect(editButton.style?.backgroundColor?.resolve({}), AppColors.brand);
  expect(logoutButton.style?.backgroundColor?.resolve({}), AppColors.error);

  await tester.tap(find.byKey(const ValueKey('sidebar-user-profile-dialog-close')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('sidebar-user-profile-dialog')), findsNothing);
});
```

Add a second test that overrides `debugPrint`, taps both bottom buttons, and expects log lines `SidebarUserProfile: 修改个人信息` and `SidebarUserProfile: 退出登录`.

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
cd frontend && flutter test test/sidebar_user_profile_capsule_test.dart
```

Expected: FAIL because the current dialog is still `AlertDialog` and lacks the new keys/buttons/log-only behavior.

## Task 2: GREEN Implementation

- [ ] **Step 1: Replace the dialog UI**

Modify `SidebarUserProfile._showUserDialog` to return a `Dialog` with:

- `key: ValueKey('sidebar-user-profile-dialog')`
- `backgroundColor: AppColors.white`
- rounded rectangle shape around `20`
- `Padding` around `20`
- top row with `_Avatar`, username/role, and close `IconButton`
- compact info rows for account, organization, recent login
- bottom `Row` with two `Expanded` `ElevatedButton`s:
  - `sidebar-user-profile-edit-button`, text `修改个人信息`, brand color
  - `sidebar-user-profile-logout-button`, text `退出登录`, error color

Button callbacks:

```dart
debugPrint('SidebarUserProfile: 修改个人信息');
debugPrint('SidebarUserProfile: 退出登录');
```

- [ ] **Step 2: Run focused tests**

Run:

```bash
cd frontend && flutter test test/sidebar_user_profile_capsule_test.dart
```

Expected: PASS.

## Task 3: Regression, Docs, Commit

- [ ] **Step 1: Update docs**

Update `docs/custom_widget_design/Sidebar-侧边栏.md` so the dialog section describes the close button, compact info rows, bottom solid buttons, and temporary log-only behavior.

- [ ] **Step 2: Run verification**

Run:

```bash
cd frontend && flutter test test/sidebar_user_profile_capsule_test.dart test/app_shell_sidebar_test.dart
cd frontend && flutter analyze
cd frontend && flutter test
```

Expected: all tests pass and analyzer reports `No issues found!`.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/superpowers/plans/2026-07-02-sidebar-user-dialog-actions.md docs/custom_widget_design/Sidebar-侧边栏.md frontend/lib/shared/widgets/navigation/sidebar_user_profile.dart frontend/test/sidebar_user_profile_capsule_test.dart frontend/test/app_shell_sidebar_test.dart
git commit -m "feat: 优化侧边栏用户弹窗操作区"
```

Expected: commit includes only this dialog UI change, tests, and docs.
