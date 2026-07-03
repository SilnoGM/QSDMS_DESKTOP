import 'dart:async';

import 'package:get/get.dart';

import '../auth/auth_controller.dart';
import 'models/settings_models.dart';
import 'repositories/settings_repository.dart';

/// 系统设置页面状态控制器。
///
/// 前端权限只影响 Tab 和按钮显隐；所有列表和变更动作仍以对应后端 API 权限
/// 校验为准，403 会落到页面错误态或操作失败提示。
class SettingsController extends GetxController {
  SettingsController({required this.repository, required this.authController});

  final SettingsRepository repository;
  final AuthController authController;

  final selectedTab = Rxn<SettingsTabKind>();

  final users = <SettingsUser>[].obs;
  final usersLoading = false.obs;
  final usersError = ''.obs;

  final roles = <SettingsRole>[].obs;
  final rolesLoading = false.obs;
  final rolesError = ''.obs;

  final permissions = <SettingsPermission>[].obs;
  final permissionsLoading = false.obs;
  final permissionsError = ''.obs;

  final isMutating = false.obs;

  late final Worker _sessionWorker;

  List<SettingsTabKind> get visibleTabs {
    return SettingsTabKind.values
        .where((tab) => authController.can(tab.listPermission))
        .toList(growable: false);
  }

  bool get canCreateUser => authController.can('system:user:create');
  bool get canUpdateUser => authController.can('system:user:update');
  bool get canChangeUserStatus => authController.can('system:user:disable');
  bool get canResetUserPassword {
    return authController.can('system:user:reset-password');
  }

  bool get canAssignUserRoles {
    return authController.can('system:user:assign-roles');
  }

  bool get canCreateRole => authController.can('system:role:create');
  bool get canUpdateRole => authController.can('system:role:update');
  bool get canAssignRolePermissions {
    return authController.can('system:role:assign-permissions');
  }

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(authController.session, (_) => _configureTabs());
    _configureTabs();
  }

  @override
  void onClose() {
    _sessionWorker.dispose();
    super.onClose();
  }

  void selectTab(SettingsTabKind tab) {
    if (!visibleTabs.contains(tab)) {
      return;
    }

    selectedTab.value = tab;
    unawaited(loadTab(tab));
  }

  Future<void> reloadSelectedTab() async {
    final tab = selectedTab.value;
    if (tab == null) {
      return;
    }
    await loadTab(tab, force: true);
  }

  Future<void> loadTab(SettingsTabKind tab, {bool force = false}) async {
    switch (tab) {
      case SettingsTabKind.users:
        await loadUsers(force: force);
        if (canCreateUser || canAssignUserRoles) {
          await loadRoles(force: force);
        }
      case SettingsTabKind.roles:
        await loadRoles(force: force);
        if (canAssignRolePermissions) {
          await loadPermissions(force: force);
        }
      case SettingsTabKind.permissions:
        await loadPermissions(force: force);
    }
  }

  Future<void> loadUsers({bool force = false}) async {
    if (!authController.can(SettingsTabKind.users.listPermission)) {
      usersError.value = '无权限访问用户管理';
      return;
    }
    if (!force && users.isNotEmpty) {
      return;
    }

    usersLoading.value = true;
    usersError.value = '';
    try {
      users.assignAll(await repository.fetchUsers());
    } on SettingsRepositoryException catch (error) {
      usersError.value = _listErrorMessage(error, '用户列表加载失败');
    } catch (_) {
      usersError.value = '用户列表加载失败';
    } finally {
      usersLoading.value = false;
    }
  }

  Future<void> loadRoles({bool force = false}) async {
    if (!force && roles.isNotEmpty) {
      return;
    }

    rolesLoading.value = true;
    rolesError.value = '';
    try {
      roles.assignAll(await repository.fetchRoles());
    } on SettingsRepositoryException catch (error) {
      rolesError.value = _listErrorMessage(error, '角色列表加载失败');
    } catch (_) {
      rolesError.value = '角色列表加载失败';
    } finally {
      rolesLoading.value = false;
    }
  }

  Future<void> loadPermissions({bool force = false}) async {
    if (!force && permissions.isNotEmpty) {
      return;
    }

    permissionsLoading.value = true;
    permissionsError.value = '';
    try {
      permissions.assignAll(await repository.fetchPermissions());
    } on SettingsRepositoryException catch (error) {
      permissionsError.value = _listErrorMessage(error, '权限列表加载失败');
    } catch (_) {
      permissionsError.value = '权限列表加载失败';
    } finally {
      permissionsLoading.value = false;
    }
  }

  Future<void> createUser({
    required String username,
    required String displayName,
    required String password,
    required List<int> roleIds,
  }) async {
    await _runMutation(
      successMessage: '用户已创建',
      action: () async {
        await repository.createUser(
          username: username,
          displayName: displayName,
          password: password,
          roleIds: roleIds,
        );
        await loadUsers(force: true);
      },
    );
  }

  Future<void> updateUser({
    required SettingsUser user,
    required String username,
    required String displayName,
  }) async {
    await _runMutation(
      successMessage: '用户资料已更新',
      action: () async {
        await repository.updateUser(
          id: user.id,
          username: username,
          displayName: displayName,
        );
        await loadUsers(force: true);
      },
    );
  }

  Future<void> updateUserStatus({
    required SettingsUser user,
    required String status,
  }) async {
    await _runMutation(
      successMessage: '用户状态已更新',
      action: () async {
        await repository.updateUserStatus(id: user.id, status: status);
        await loadUsers(force: true);
      },
    );
  }

  Future<void> resetUserPassword({
    required SettingsUser user,
    required String password,
  }) async {
    await _runMutation(
      successMessage: '密码已重置',
      action: () async {
        await repository.resetUserPassword(id: user.id, password: password);
      },
    );
  }

  Future<void> assignUserRoles({
    required SettingsUser user,
    required List<int> roleIds,
  }) async {
    await _runMutation(
      successMessage: '用户角色已更新',
      action: () async {
        await repository.assignUserRoles(id: user.id, roleIds: roleIds);
        await loadUsers(force: true);
      },
    );
  }

  Future<void> createRole({
    required String code,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    await _runMutation(
      successMessage: '角色已创建',
      action: () async {
        await repository.createRole(
          code: code,
          name: name,
          description: description,
          isActive: isActive,
        );
        await loadRoles(force: true);
      },
    );
  }

  Future<void> updateRole({
    required SettingsRole role,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    await _runMutation(
      successMessage: '角色已更新',
      action: () async {
        await repository.updateRole(
          id: role.id,
          name: name,
          description: description,
          isActive: isActive,
        );
        await loadRoles(force: true);
      },
    );
  }

  Future<void> assignRolePermissions({
    required SettingsRole role,
    required List<int> permissionIds,
  }) async {
    await _runMutation(
      successMessage: '角色权限已更新',
      action: () async {
        await repository.assignRolePermissions(
          id: role.id,
          permissionIds: permissionIds,
        );
        await loadRoles(force: true);
      },
    );
  }

  void _configureTabs() {
    final tabs = visibleTabs;
    if (tabs.isEmpty) {
      selectedTab.value = null;
      return;
    }

    final current = selectedTab.value;
    if (current == null || !tabs.contains(current)) {
      selectedTab.value = tabs.first;
      unawaited(loadTab(tabs.first));
    }
  }

  Future<void> _runMutation({
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    if (isMutating.value) {
      return;
    }

    isMutating.value = true;
    try {
      await action();
      _showMessage(title: '操作成功', message: successMessage);
    } on SettingsRepositoryException catch (error) {
      _showMessage(title: '操作失败', message: _operationErrorMessage(error));
    } catch (_) {
      _showMessage(title: '操作失败', message: '请求失败，请稍后重试');
    } finally {
      isMutating.value = false;
    }
  }

  String _listErrorMessage(SettingsRepositoryException error, String fallback) {
    if (error.isForbidden) {
      return '无权限访问此列表';
    }
    return error.message.isNotEmpty ? error.message : fallback;
  }

  String _operationErrorMessage(SettingsRepositoryException error) {
    if (error.isForbidden) {
      return '无权限执行此操作';
    }
    return error.message.isNotEmpty ? error.message : '操作失败';
  }

  void _showMessage({required String title, required String message}) {
    if (Get.context == null) {
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
