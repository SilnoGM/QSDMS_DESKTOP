import 'package:shared_preferences/shared_preferences.dart';

/// 非敏感认证偏好存储。
///
/// 这里只保存“是否记住登录”和“最后一次用户名”。token 和密码都不是偏好配置，
/// 不能进入 `SharedPreferences`，避免被普通配置备份、导出或日志化。
class PreferenceStorage {
  static const rememberLoginKey = 'auth.rememberLogin';
  static const lastUsernameKey = 'auth.lastUsername';

  static const allowedKeys = <String>{rememberLoginKey, lastUsernameKey};

  Future<bool> readRememberLogin() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(rememberLoginKey) ?? false;
  }

  Future<String?> readLastUsername() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(lastUsernameKey);
  }

  Future<void> saveRememberedLogin({required String username}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(rememberLoginKey, true);
    await preferences.setString(lastUsernameKey, username);
  }

  Future<void> clearRememberedLogin() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(rememberLoginKey);
    await preferences.remove(lastUsernameKey);
  }
}
