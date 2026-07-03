/// 登录用户快照。
///
/// 后端 `user` 字段可能随业务扩展增加属性，核心身份字段用强类型承接，
/// 其余原始数据保留在 `raw` 中，避免前端为了未使用字段提前设计复杂模型。
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.raw,
  });

  final String id;
  final String username;
  final String displayName;
  final Map<String, dynamic> raw;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final username = _readString(json, const ['username', 'account', 'name']);
    return AuthUser(
      id: _readString(json, const ['id', 'userId', 'uuid']) ?? '',
      username: username ?? '',
      displayName:
          _readString(json, const ['displayName', 'realName', 'nickname']) ??
          username ??
          '',
      raw: _sanitizeUserRaw(json),
    );
  }
}

/// 不含 token 的认证会话快照。
///
/// `/auth/session` 只返回用户、角色、权限和菜单，因此快照模型不要求 token。
class AuthSessionSnapshot {
  const AuthSessionSnapshot({
    required this.user,
    required this.roles,
    required this.permissions,
    required this.menus,
  });

  final AuthUser user;
  final Set<String> roles;
  final Set<String> permissions;
  final List<Map<String, dynamic>> menus;

  factory AuthSessionSnapshot.fromResponseData(Map<String, dynamic> data) {
    final userData = data['user'];
    return AuthSessionSnapshot(
      user: userData is Map<String, dynamic>
          ? AuthUser.fromJson(userData)
          : AuthUser.fromJson(const <String, dynamic>{}),
      roles: _readStringSet(data['roles']),
      permissions: _readStringSet(data['permissions']),
      menus: _readMenus(data['menus']),
    );
  }
}

/// 后端登录 / refresh 返回的短生命周期 token 结果。
///
/// 安全边界：
/// - token 只允许从仓储短暂流转到 `TokenStorage`；
/// - 全局 Controller 和页面只能持有 `snapshot`，不能把 token 放进可观察状态；
/// - 不继承 `AuthSessionSnapshot`，避免误把带 token 对象当作页面 session 使用。
class AuthTokenResult {
  const AuthTokenResult({
    required this.accessToken,
    required this.refreshToken,
    required this.snapshot,
  });

  final String accessToken;
  final String refreshToken;
  final AuthSessionSnapshot snapshot;

  factory AuthTokenResult.fromResponseData(Map<String, dynamic> data) {
    final snapshot = AuthSessionSnapshot.fromResponseData(data);
    return AuthTokenResult(
      accessToken: _requireString(data, 'accessToken'),
      refreshToken: _requireString(data, 'refreshToken'),
      snapshot: snapshot,
    );
  }
}

String _requireString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Auth response missing $key');
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

Set<String> _readStringSet(Object? value) {
  if (value is! Iterable) {
    return const <String>{};
  }

  return value
      .map((item) {
        if (item is String) {
          return item;
        }
        if (item is Map<String, dynamic>) {
          return _readString(item, const ['code', 'name', 'id']);
        }
        return null;
      })
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toSet();
}

List<Map<String, dynamic>> _readMenus(Object? value) {
  if (value is! Iterable) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(Map<String, dynamic>.unmodifiable)
      .toList(growable: false);
}

Map<String, dynamic> _sanitizeUserRaw(Map<String, dynamic> json) {
  final filtered = <String, dynamic>{};
  for (final entry in json.entries) {
    if (_isSensitiveUserRawKey(entry.key)) {
      continue;
    }
    filtered[entry.key] = entry.value;
  }
  return Map<String, dynamic>.unmodifiable(filtered);
}

bool _isSensitiveUserRawKey(String key) {
  // 后端 user 对象可能追加临时认证字段；raw 会进入全局 session 快照，
  // 因此按字段语义剔除 token、password、hash 类数据，避免 UI 层误读或泄漏。
  final normalized = key.toLowerCase();
  return normalized.contains('token') ||
      normalized.contains('password') ||
      normalized.contains('hash');
}
