/// 系统设置权限 Tab。
///
/// Tab 的可见性只做前端体验控制，不作为安全边界；真实权限仍以后端 API
/// 校验结果为准。
enum SettingsTabKind {
  users('用户管理', 'system:user:list'),
  roles('角色管理', 'system:role:list'),
  permissions('权限管理', 'system:permission:list');

  const SettingsTabKind(this.label, this.listPermission);

  final String label;
  final String listPermission;
}

/// 用户状态。
abstract final class SettingsUserStatus {
  static const active = 'ACTIVE';
  static const disabled = 'DISABLED';
  static const locked = 'LOCKED';
}

/// 用户列表行。
class SettingsUser {
  const SettingsUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.status,
    required this.roles,
  });

  final String id;
  final String username;
  final String displayName;
  final String status;
  final List<SettingsRoleBrief> roles;

  factory SettingsUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileDisplayName = profile is Map<String, dynamic>
        ? _readString(profile, const ['displayName'])
        : null;
    final username = _readString(json, const ['username']) ?? '';
    final displayName =
        _readString(json, const ['displayName']) ??
        profileDisplayName ??
        username;

    return SettingsUser(
      id: _readString(json, const ['id']) ?? '',
      username: username,
      displayName: displayName,
      status: _readString(json, const ['status']) ?? SettingsUserStatus.active,
      roles: _readMapList(
        json['roles'],
      ).map(SettingsRoleBrief.fromJson).toList(growable: false),
    );
  }

  String get statusLabel {
    return switch (status) {
      SettingsUserStatus.active => '启用',
      SettingsUserStatus.disabled => '禁用',
      SettingsUserStatus.locked => '锁定',
      _ => status,
    };
  }

  String get roleSummary {
    if (roles.isEmpty) {
      return '未分配角色';
    }
    return roles.map((role) => role.name).join('、');
  }

  List<int> get roleIds => roles.map((role) => role.id).toList(growable: false);
}

/// 用户列表内嵌的角色摘要。
class SettingsRoleBrief {
  const SettingsRoleBrief({
    required this.id,
    required this.code,
    required this.name,
    required this.isSystem,
    required this.isActive,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;

  factory SettingsRoleBrief.fromJson(Map<String, dynamic> json) {
    final code = _readString(json, const ['code']) ?? '';
    return SettingsRoleBrief(
      id: _readInt(json, const ['id']) ?? 0,
      code: code,
      name: _readString(json, const ['name']) ?? code,
      description: _readString(json, const ['description']),
      isSystem: _readBool(json, const ['isSystem']),
      isActive: _readBool(json, const ['isActive'], defaultValue: true),
    );
  }
}

/// 角色列表行。
class SettingsRole {
  const SettingsRole({
    required this.id,
    required this.code,
    required this.name,
    required this.isSystem,
    required this.isActive,
    required this.permissions,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final List<SettingsPermission> permissions;

  factory SettingsRole.fromJson(Map<String, dynamic> json) {
    final code = _readString(json, const ['code']) ?? '';
    return SettingsRole(
      id: _readInt(json, const ['id']) ?? 0,
      code: code,
      name: _readString(json, const ['name']) ?? code,
      description: _readString(json, const ['description']),
      isSystem: _readBool(json, const ['isSystem']),
      isActive: _readBool(json, const ['isActive'], defaultValue: true),
      permissions: _readMapList(
        json['permissions'],
      ).map(SettingsPermission.fromJson).toList(growable: false),
    );
  }

  List<int> get permissionIds {
    return permissions
        .map((permission) => permission.id)
        .toList(growable: false);
  }

  String get activeLabel => isActive ? '启用' : '停用';
}

/// 权限列表行。
class SettingsPermission {
  const SettingsPermission({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.module,
    required this.sortOrder,
    required this.isSystem,
    required this.isActive,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String type;
  final String module;
  final String? description;
  final int sortOrder;
  final bool isSystem;
  final bool isActive;

  factory SettingsPermission.fromJson(Map<String, dynamic> json) {
    final code = _readString(json, const ['code']) ?? '';
    return SettingsPermission(
      id: _readInt(json, const ['id']) ?? 0,
      code: code,
      name: _readString(json, const ['name']) ?? code,
      type: _readString(json, const ['type']) ?? '',
      module: _readString(json, const ['module']) ?? '',
      description: _readString(json, const ['description']),
      sortOrder: _readInt(json, const ['sortOrder']) ?? 0,
      isSystem: _readBool(json, const ['isSystem']),
      isActive: _readBool(json, const ['isActive'], defaultValue: true),
    );
  }

  String get activeLabel => isActive ? '启用' : '停用';
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! Iterable) {
    return const <Map<String, dynamic>>[];
  }

  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

int? _readInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
  }
  return null;
}

bool _readBool(
  Map<String, dynamic> data,
  List<String> keys, {
  bool defaultValue = false,
}) {
  for (final key in keys) {
    final value = data[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
  }
  return defaultValue;
}
