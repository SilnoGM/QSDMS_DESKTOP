import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qsdms_desktop_frontend/modules/auth/storage/preference_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('PreferenceStorage 只保存 rememberLogin 和 lastUsername', () async {
    final storage = PreferenceStorage();

    await storage.saveRememberedLogin(username: 'SilnoGM');

    final preferences = await SharedPreferences.getInstance();

    expect(await storage.readRememberLogin(), isTrue);
    expect(await storage.readLastUsername(), 'SilnoGM');
    expect(preferences.getKeys(), {
      PreferenceStorage.rememberLoginKey,
      PreferenceStorage.lastUsernameKey,
    });
    expect(preferences.getString('auth.accessToken'), isNull);
    expect(preferences.getString('auth.refreshToken'), isNull);
  });

  test('clearRememberedLogin 清理记住登录状态和最后用户名', () async {
    final storage = PreferenceStorage();

    await storage.saveRememberedLogin(username: 'SilnoGM');
    await storage.clearRememberedLogin();

    expect(await storage.readRememberLogin(), isFalse);
    expect(await storage.readLastUsername(), isNull);
  });
}
