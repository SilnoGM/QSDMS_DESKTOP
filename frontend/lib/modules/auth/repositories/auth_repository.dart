import 'package:dio/dio.dart';

import '../../../shared/services/api_client.dart';
import '../models/auth_session.dart';

/// 认证接口仓储。
///
/// 仓储只负责调用后端认证端点和解析统一响应，不持有 token 存储策略；
/// token 的落点由 `AuthController` 和 `ApiClient` 统一处理。
class AuthRepository {
  AuthRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<AuthTokenResult> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{'username': username, 'password': password},
      options: Options(
        extra: const <String, Object>{ApiClient.skipAuthExtraKey: true},
      ),
    );

    return AuthTokenResult.fromResponseData(_unwrapMapData(response.data));
  }

  Future<AuthTokenResult> refreshSession(String refreshToken) async {
    final response = await apiClient.dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: <String, dynamic>{'refreshToken': refreshToken},
      options: Options(
        extra: const <String, Object>{ApiClient.skipAuthExtraKey: true},
      ),
    );

    return AuthTokenResult.fromResponseData(_unwrapMapData(response.data));
  }

  Future<AuthSessionSnapshot> fetchSession() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/auth/session',
    );

    return AuthSessionSnapshot.fromResponseData(_unwrapMapData(response.data));
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>('/auth/me');
    return _unwrapMapData(response.data);
  }

  Future<Set<String>> fetchPermissions() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/auth/permissions',
    );
    final payload = _unwrapPayload(response.data);
    final permissions = payload is Map<String, dynamic>
        ? payload['permissions']
        : payload;
    if (permissions is Iterable) {
      return permissions.whereType<String>().toSet();
    }
    return const <String>{};
  }

  Future<void> logout(String? refreshToken) async {
    await apiClient.dio.post<Map<String, dynamic>>(
      '/auth/logout',
      data: refreshToken == null
          ? null
          : <String, dynamic>{'refreshToken': refreshToken},
    );
  }

  Map<String, dynamic> _unwrapMapData(Map<String, dynamic>? responseBody) {
    final payload = _unwrapPayload(responseBody);
    if (payload is Map<String, dynamic>) {
      return payload;
    }

    throw const FormatException('Auth response data is invalid');
  }

  Object? _unwrapPayload(Map<String, dynamic>? responseBody) {
    if (responseBody == null) {
      throw const FormatException('Auth response body is empty');
    }

    final code = responseBody['code'];
    final success = code == null || code == 0 || code == 200 || code == '0';
    if (!success) {
      final message = responseBody['message'];
      throw AuthRepositoryException(
        message is String && message.isNotEmpty ? message : '认证请求失败',
      );
    }

    return responseBody['data'];
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AuthRepositoryException: $message';
}
