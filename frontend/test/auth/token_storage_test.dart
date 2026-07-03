import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qsdms_desktop_frontend/modules/auth/storage/token_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('TokenStorage 仅把 accessToken 放在内存，refreshToken 放在安全存储', () async {
    final secureStore = _MemorySecureTokenStore();
    final storage = TokenStorage(secureStore: secureStore);

    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    final preferences = await SharedPreferences.getInstance();
    final restartedStorage = TokenStorage(secureStore: secureStore);

    expect(storage.accessToken, 'access-token');
    expect(await storage.readRefreshToken(), 'refresh-token');
    expect(restartedStorage.accessToken, isNull);
    expect(await restartedStorage.readRefreshToken(), 'refresh-token');
    expect(preferences.getKeys(), isNot(contains('auth.accessToken')));
    expect(preferences.getKeys(), isNot(contains('auth.refreshToken')));
    expect(secureStore.values[TokenStorage.refreshTokenKey], 'refresh-token');
  });

  test('clear 清理内存 accessToken 与安全存储 refreshToken', () async {
    final secureStore = _MemorySecureTokenStore();
    final storage = TokenStorage(secureStore: secureStore);

    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    await storage.clear();

    expect(storage.accessToken, isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(secureStore.values, isEmpty);
  });
}

class _MemorySecureTokenStore implements SecureTokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
