import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 可替换的安全存储接口。
///
/// 生产环境使用 `flutter_secure_storage`，测试环境注入内存 fake，避免 widget /
/// unit test 依赖真实平台插件。
abstract interface class SecureTokenStore {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});
}

class FlutterSecureTokenStore implements SecureTokenStore {
  FlutterSecureTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // 本地 Flutter macOS 调试包通常没有开发签名证书。关闭 Data
            // Protection Keychain 后仍使用系统 Keychain，但不额外要求
            // Keychain Sharing entitlement，避免安全存储写入阶段阻断登录。
            mOptions: macOsOptions,
          );

  static const macOsOptions = MacOsOptions(usesDataProtectionKeychain: false);

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

/// 认证 token 存储边界。
///
/// 安全约束：
/// - `accessToken` 只保存在内存字段中，进程结束即丢失，降低短期凭证落盘泄露面；
/// - `refreshToken` 只进入系统安全存储，用于应用重启后换取新会话；
/// - 不使用 `SharedPreferences` 保存任何 token，避免普通偏好配置介质承载敏感凭证。
class TokenStorage {
  TokenStorage({SecureTokenStore? secureStore})
    : _secureStore = secureStore ?? FlutterSecureTokenStore();

  static const refreshTokenKey = 'auth.refreshToken';

  final SecureTokenStore _secureStore;
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<String?> readRefreshToken() {
    return _secureStore.read(key: refreshTokenKey);
  }

  Future<void> saveAccessToken(String accessToken) async {
    _accessToken = accessToken;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _secureStore.write(key: refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    await _secureStore.delete(key: refreshTokenKey);
  }
}
