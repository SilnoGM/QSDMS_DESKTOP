import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/layout/app_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/services/api_client.dart';
import '../auth/auth_controller.dart';
import 'models/settings_models.dart';
import 'repositories/settings_repository.dart';
import 'settings_controller.dart';

/// 系统设置页面。
///
/// 子能力以 `/settings` 内部 Tabs 承载，不注册侧边栏二级路由；按钮只按
/// `system:*` 权限做显隐，最终安全边界仍是后端 API 权限校验。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = _ensureController();

    return Scaffold(
      body: AppShell(
        activeMenuId: 'settings',
        child: Obx(() {
          final tabs = controller.visibleTabs;
          final selected = controller.selectedTab.value;
          return _SettingsContent(
            controller: controller,
            tabs: tabs,
            selected: tabs.contains(selected)
                ? selected
                : tabs.isEmpty
                ? null
                : tabs.first,
          );
        }),
      ),
    );
  }

  SettingsController _ensureController() {
    if (Get.isRegistered<SettingsController>()) {
      return Get.find<SettingsController>();
    }

    return Get.put(
      SettingsController(
        repository: SettingsRepository(apiClient: Get.find<ApiClient>()),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.controller,
    required this.tabs,
    required this.selected,
  });

  final SettingsController controller;
  final List<SettingsTabKind> tabs;
  final SettingsTabKind? selected;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const _NoPermissionState();
    }

    final selectedTab = selected ?? tabs.first;
    final selectedIndex = tabs.indexOf(selectedTab);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsHeader(),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: DefaultTabController(
              key: ValueKey(
                '${tabs.map((tab) => tab.name).join('|')}-$selectedIndex',
              ),
              length: tabs.length,
              initialIndex: selectedIndex,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.brand,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.brand,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [for (final tab in tabs) Tab(text: tab.label)],
                onTap: (index) => controller.selectTab(tabs[index]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildTab(context, selectedTab)),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, SettingsTabKind tab) {
    return switch (tab) {
      SettingsTabKind.users => _UsersManagementTab(controller: controller),
      SettingsTabKind.roles => _RolesManagementTab(controller: controller),
      SettingsTabKind.permissions => _PermissionsManagementTab(
        controller: controller,
      ),
    };
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '系统设置',
          style: TextStyle(
            color: AppColors.textHeading,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '按当前账号权限管理用户、角色和权限。',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _UsersManagementTab extends StatelessWidget {
  const _UsersManagementTab({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return _ManagementPanel(
        title: '用户列表',
        count: controller.users.length,
        onRefresh: () => unawaited(controller.loadUsers(force: true)),
        actions: [
          if (controller.canCreateUser)
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(context, controller),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('创建用户'),
            ),
        ],
        child: _buildUserBody(context),
      );
    });
  }

  Widget _buildUserBody(BuildContext context) {
    if (controller.usersLoading.value) {
      return const _LoadingState(text: '用户列表加载中');
    }
    if (controller.usersError.value.isNotEmpty) {
      return _ErrorState(
        message: controller.usersError.value,
        onRetry: () => unawaited(controller.loadUsers(force: true)),
      );
    }
    if (controller.users.isEmpty) {
      return const _EmptyState(text: '暂无用户数据');
    }

    return _DataTableSurface(
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        columns: const [
          DataColumn(label: Text('用户名')),
          DataColumn(label: Text('显示名称')),
          DataColumn(label: Text('状态')),
          DataColumn(label: Text('角色')),
          DataColumn(label: Text('操作')),
        ],
        rows: [
          for (final user in controller.users)
            DataRow(
              cells: [
                DataCell(_CellText(user.username)),
                DataCell(_CellText(user.displayName)),
                DataCell(_StatusPill(text: user.statusLabel)),
                DataCell(_CellText(user.roleSummary, width: 220)),
                DataCell(_UserActions(controller: controller, user: user)),
              ],
            ),
        ],
      ),
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({required this.controller, required this.user});

  final SettingsController controller;
  final SettingsUser user;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        if (controller.canUpdateUser)
          TextButton(
            onPressed: () =>
                _showUserDialog(context, controller, editingUser: user),
            child: const Text('编辑'),
          ),
        if (controller.canChangeUserStatus)
          PopupMenuButton<String>(
            tooltip: '变更状态',
            onSelected: (status) => unawaited(
              controller.updateUserStatus(user: user, status: status),
            ),
            itemBuilder: (context) => [
              for (final option in _statusOptions(user.status))
                PopupMenuItem(value: option.status, child: Text(option.label)),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text('状态', style: TextStyle(color: AppColors.link)),
            ),
          ),
        if (controller.canResetUserPassword)
          TextButton(
            onPressed: () =>
                _showResetPasswordDialog(context, controller, user),
            child: const Text('重置密码'),
          ),
        if (controller.canAssignUserRoles)
          TextButton(
            onPressed: () =>
                _showAssignUserRolesDialog(context, controller, user),
            child: const Text('分配角色'),
          ),
      ],
    );
  }
}

class _RolesManagementTab extends StatelessWidget {
  const _RolesManagementTab({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return _ManagementPanel(
        title: '角色列表',
        count: controller.roles.length,
        onRefresh: () => unawaited(controller.loadRoles(force: true)),
        actions: [
          if (controller.canCreateRole)
            ElevatedButton.icon(
              onPressed: () => _showRoleDialog(context, controller),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('创建角色'),
            ),
        ],
        child: _buildRoleBody(context),
      );
    });
  }

  Widget _buildRoleBody(BuildContext context) {
    if (controller.rolesLoading.value) {
      return const _LoadingState(text: '角色列表加载中');
    }
    if (controller.rolesError.value.isNotEmpty) {
      return _ErrorState(
        message: controller.rolesError.value,
        onRetry: () => unawaited(controller.loadRoles(force: true)),
      );
    }
    if (controller.roles.isEmpty) {
      return const _EmptyState(text: '暂无角色数据');
    }

    return _DataTableSurface(
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        columns: const [
          DataColumn(label: Text('编码')),
          DataColumn(label: Text('名称')),
          DataColumn(label: Text('系统角色')),
          DataColumn(label: Text('状态')),
          DataColumn(label: Text('权限数')),
          DataColumn(label: Text('操作')),
        ],
        rows: [
          for (final role in controller.roles)
            DataRow(
              cells: [
                DataCell(_CellText(role.code, width: 150)),
                DataCell(_CellText(role.name)),
                DataCell(Text(role.isSystem ? '是' : '否')),
                DataCell(_StatusPill(text: role.activeLabel)),
                DataCell(Text('${role.permissions.length}')),
                DataCell(_RoleActions(controller: controller, role: role)),
              ],
            ),
        ],
      ),
    );
  }
}

class _RoleActions extends StatelessWidget {
  const _RoleActions({required this.controller, required this.role});

  final SettingsController controller;
  final SettingsRole role;

  bool get _locksPermissionEdit {
    return role.isSystem || role.code == 'SUPER_ADMIN';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        if (controller.canUpdateRole)
          TextButton(
            onPressed: () =>
                _showRoleDialog(context, controller, editingRole: role),
            child: const Text('编辑'),
          ),
        if (controller.canUpdateRole)
          TextButton(
            onPressed: role.isSystem
                ? null
                : () => unawaited(
                    controller.updateRole(
                      role: role,
                      name: role.name,
                      description: role.description ?? '',
                      isActive: !role.isActive,
                    ),
                  ),
            child: Text(role.isActive ? '停用' : '启用'),
          ),
        if (controller.canAssignRolePermissions)
          TextButton(
            onPressed: _locksPermissionEdit
                ? null
                : () => _showAssignRolePermissionsDialog(
                    context,
                    controller,
                    role,
                  ),
            child: const Text('分配权限'),
          ),
      ],
    );
  }
}

class _PermissionsManagementTab extends StatelessWidget {
  const _PermissionsManagementTab({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return _ManagementPanel(
        title: '权限列表',
        count: controller.permissions.length,
        onRefresh: () => unawaited(controller.loadPermissions(force: true)),
        actions: const [],
        child: _buildPermissionBody(),
      );
    });
  }

  Widget _buildPermissionBody() {
    if (controller.permissionsLoading.value) {
      return const _LoadingState(text: '权限列表加载中');
    }
    if (controller.permissionsError.value.isNotEmpty) {
      return _ErrorState(
        message: controller.permissionsError.value,
        onRetry: () => unawaited(controller.loadPermissions(force: true)),
      );
    }
    if (controller.permissions.isEmpty) {
      return const _EmptyState(text: '暂无权限数据');
    }

    return _DataTableSurface(
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Text('模块')),
          DataColumn(label: Text('类型')),
          DataColumn(label: Text('编码')),
          DataColumn(label: Text('名称')),
          DataColumn(label: Text('状态')),
        ],
        rows: [
          for (final permission in controller.permissions)
            DataRow(
              cells: [
                DataCell(_CellText(permission.module, width: 110)),
                DataCell(_CellText(permission.type, width: 90)),
                DataCell(_CellText(permission.code, width: 220)),
                DataCell(_CellText(permission.name, width: 160)),
                DataCell(_StatusPill(text: permission.activeLabel)),
              ],
            ),
        ],
      ),
    );
  }
}

class _ManagementPanel extends StatelessWidget {
  const _ManagementPanel({
    required this.title,
    required this.count,
    required this.onRefresh,
    required this.actions,
    required this.child,
  });

  final String title;
  final int count;
  final VoidCallback onRefresh;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                _CountBadge(count: count),
                const Spacer(),
                IconButton(
                  tooltip: '刷新',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
                const SizedBox(width: 8),
                ...actions,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DataTableSurface extends StatelessWidget {
  const _DataTableSurface({required this.child});

  final DataTable child;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}

class _NoPermissionState extends StatelessWidget {
  const _NoPermissionState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _StateMessage(
        icon: Icons.lock_outline_rounded,
        title: '暂无系统设置权限',
        description: '当前账号没有用户、角色或权限管理入口。',
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StateMessage(
            icon: Icons.error_outline_rounded,
            title: message,
            description: '请确认账号权限或稍后重试。',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _StateMessage(
        icon: Icons.inbox_outlined,
        title: text,
        description: '暂无可展示记录。',
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: AppColors.textTertiary),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.text, {this.width = 140});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textBody, fontSize: 13),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandSubtleBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.brandText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<void> _showUserDialog(
  BuildContext context,
  SettingsController controller, {
  SettingsUser? editingUser,
}) async {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController(text: editingUser?.username ?? '');
  final displayName = TextEditingController(
    text: editingUser?.displayName ?? '',
  );
  final password = TextEditingController();
  final selectedRoleIds = editingUser?.roleIds.toSet() ?? <int>{};
  final isEditing = editingUser != null;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? '编辑用户' : '创建用户'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: username,
                        decoration: const InputDecoration(labelText: '用户名'),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: displayName,
                        decoration: const InputDecoration(labelText: '显示名称'),
                        validator: _requiredValidator,
                      ),
                      if (!isEditing) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: '初始密码'),
                          validator: _passwordValidator,
                        ),
                        const SizedBox(height: 14),
                        _RoleCheckboxGroup(
                          roles: controller.roles,
                          selectedRoleIds: selectedRoleIds,
                          onChanged: (roleId, selected) {
                            setState(() {
                              if (selected) {
                                selectedRoleIds.add(roleId);
                              } else {
                                selectedRoleIds.remove(roleId);
                              }
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop();
                  if (isEditing) {
                    unawaited(
                      controller.updateUser(
                        user: editingUser,
                        username: username.text.trim(),
                        displayName: displayName.text.trim(),
                      ),
                    );
                    return;
                  }
                  unawaited(
                    controller.createUser(
                      username: username.text.trim(),
                      displayName: displayName.text.trim(),
                      password: password.text,
                      roleIds: selectedRoleIds.toList(growable: false),
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showResetPasswordDialog(
  BuildContext context,
  SettingsController controller,
  SettingsUser user,
) async {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('重置密码：${user.username}'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新密码'),
              validator: _passwordValidator,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.of(context).pop();
              unawaited(
                controller.resetUserPassword(
                  user: user,
                  password: password.text,
                ),
              );
            },
            child: const Text('提交'),
          ),
        ],
      );
    },
  );
}

Future<void> _showAssignUserRolesDialog(
  BuildContext context,
  SettingsController controller,
  SettingsUser user,
) async {
  final selectedRoleIds = user.roleIds.toSet();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('分配角色：${user.username}'),
            content: SizedBox(
              width: 420,
              child: _RoleCheckboxGroup(
                roles: controller.roles,
                selectedRoleIds: selectedRoleIds,
                onChanged: (roleId, selected) {
                  setState(() {
                    if (selected) {
                      selectedRoleIds.add(roleId);
                    } else {
                      selectedRoleIds.remove(roleId);
                    }
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(
                    controller.assignUserRoles(
                      user: user,
                      roleIds: selectedRoleIds.toList(growable: false),
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showRoleDialog(
  BuildContext context,
  SettingsController controller, {
  SettingsRole? editingRole,
}) async {
  final formKey = GlobalKey<FormState>();
  final code = TextEditingController(text: editingRole?.code ?? '');
  final name = TextEditingController(text: editingRole?.name ?? '');
  final description = TextEditingController(
    text: editingRole?.description ?? '',
  );
  var isActive = editingRole?.isActive ?? true;
  final isEditing = editingRole != null;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? '编辑角色' : '创建角色'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: code,
                      enabled: !isEditing,
                      decoration: const InputDecoration(labelText: '角色编码'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: '角色名称'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(labelText: '说明'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: isActive,
                      onChanged: editingRole?.isSystem == true
                          ? null
                          : (value) => setState(() => isActive = value ?? true),
                      title: const Text('启用角色'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop();
                  if (isEditing) {
                    unawaited(
                      controller.updateRole(
                        role: editingRole,
                        name: name.text.trim(),
                        description: description.text,
                        isActive: isActive,
                      ),
                    );
                    return;
                  }
                  unawaited(
                    controller.createRole(
                      code: code.text.trim(),
                      name: name.text.trim(),
                      description: description.text,
                      isActive: isActive,
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showAssignRolePermissionsDialog(
  BuildContext context,
  SettingsController controller,
  SettingsRole role,
) async {
  final selectedPermissionIds = role.permissionIds.toSet();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('分配权限：${role.name}'),
            content: SizedBox(
              width: 520,
              height: 460,
              child: controller.permissions.isEmpty
                  ? const _EmptyState(text: '暂无可分配权限')
                  : ListView(
                      children: [
                        for (final permission in controller.permissions)
                          CheckboxListTile(
                            value: selectedPermissionIds.contains(
                              permission.id,
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedPermissionIds.add(permission.id);
                                } else {
                                  selectedPermissionIds.remove(permission.id);
                                }
                              });
                            },
                            title: Text(permission.name),
                            subtitle: Text(permission.code),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(
                    controller.assignRolePermissions(
                      role: role,
                      permissionIds: selectedPermissionIds.toList(
                        growable: false,
                      ),
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _RoleCheckboxGroup extends StatelessWidget {
  const _RoleCheckboxGroup({
    required this.roles,
    required this.selectedRoleIds,
    required this.onChanged,
  });

  final List<SettingsRole> roles;
  final Set<int> selectedRoleIds;
  final void Function(int roleId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('暂无可选角色', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '角色',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final role in roles)
                CheckboxListTile(
                  value: selectedRoleIds.contains(role.id),
                  onChanged: role.isActive
                      ? (value) => onChanged(role.id, value ?? false)
                      : null,
                  title: Text(role.name),
                  subtitle: Text(role.code),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

typedef _StatusOption = ({String status, String label});

List<_StatusOption> _statusOptions(String currentStatus) {
  return switch (currentStatus) {
    SettingsUserStatus.active => const [
      (status: SettingsUserStatus.disabled, label: '禁用'),
      (status: SettingsUserStatus.locked, label: '锁定'),
    ],
    SettingsUserStatus.disabled => const [
      (status: SettingsUserStatus.active, label: '启用'),
      (status: SettingsUserStatus.locked, label: '锁定'),
    ],
    SettingsUserStatus.locked => const [
      (status: SettingsUserStatus.active, label: '启用'),
      (status: SettingsUserStatus.disabled, label: '禁用'),
    ],
    _ => const [
      (status: SettingsUserStatus.active, label: '启用'),
      (status: SettingsUserStatus.disabled, label: '禁用'),
      (status: SettingsUserStatus.locked, label: '锁定'),
    ],
  };
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '必填';
  }
  return null;
}

String? _passwordValidator(String? value) {
  if (value == null || value.length < 8) {
    return '至少 8 位';
  }
  return null;
}
