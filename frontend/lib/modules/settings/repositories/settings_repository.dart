import 'package:dio/dio.dart';

import '../../../shared/services/api_client.dart';
import '../models/settings_models.dart';

/// 系统设置 API 仓储。
///
/// 仓储只处理 HTTP 调用和 `{ code, message, data }` 统一响应解析；页面和
/// Controller 不接触 Dio 细节，也不会把 password/token/hash 写入日志。
class SettingsRepository {
  const SettingsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<SettingsUser>> fetchUsers() async {
    final payload = await _getPayload('/users');
    return _readList(
      payload,
    ).map(SettingsUser.fromJson).toList(growable: false);
  }

  Future<SettingsUser> createUser({
    required String username,
    required String displayName,
    required String password,
    required List<int> roleIds,
  }) async {
    final payload = await _sendPayload(
      method: _HttpMethod.post,
      path: '/users',
      data: <String, dynamic>{
        'username': username,
        'displayName': displayName,
        'password': password,
        'roleIds': roleIds,
      },
    );
    return SettingsUser.fromJson(_requireMap(payload));
  }

  Future<SettingsUser> updateUser({
    required String id,
    required String username,
    required String displayName,
  }) async {
    final payload = await _sendPayload(
      method: _HttpMethod.patch,
      path: '/users/$id',
      data: <String, dynamic>{'username': username, 'displayName': displayName},
    );
    return SettingsUser.fromJson(_requireMap(payload));
  }

  Future<SettingsUser> updateUserStatus({
    required String id,
    required String status,
  }) async {
    final payload = await _sendPayload(
      method: _HttpMethod.patch,
      path: '/users/$id/status',
      data: <String, dynamic>{'status': status},
    );
    return SettingsUser.fromJson(_requireMap(payload));
  }

  Future<void> resetUserPassword({
    required String id,
    required String password,
  }) async {
    await _sendPayload(
      method: _HttpMethod.post,
      path: '/users/$id/reset-password',
      data: <String, dynamic>{'password': password},
    );
  }

  Future<SettingsUser> assignUserRoles({
    required String id,
    required List<int> roleIds,
  }) async {
    final payload = await _sendPayload(
      method: _HttpMethod.put,
      path: '/users/$id/roles',
      data: <String, dynamic>{'roleIds': roleIds},
    );
    return SettingsUser.fromJson(_requireMap(payload));
  }

  Future<List<SettingsRole>> fetchRoles() async {
    final payload = await _getPayload('/roles');
    return _readList(
      payload,
    ).map(SettingsRole.fromJson).toList(growable: false);
  }

  Future<SettingsRole> createRole({
    required String code,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    final payload = await _sendPayload(
      method: _HttpMethod.post,
      path: '/roles',
      data: <String, dynamic>{
        'code': code,
        'name': name,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'isActive': isActive,
      },
    );
    return SettingsRole.fromJson(_requireMap(payload));
  }

  Future<SettingsRole> updateRole({
    required int id,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    final payload = await _sendPayload(
      method: _HttpMethod.patch,
      path: '/roles/$id',
      data: <String, dynamic>{
        'name': name,
        'description': description.trim().isEmpty ? null : description.trim(),
        'isActive': isActive,
      },
    );
    return SettingsRole.fromJson(_requireMap(payload));
  }

  Future<SettingsRole> assignRolePermissions({
    required int id,
    required List<int> permissionIds,
  }) async {
    final payload = await _sendPayload(
      method: _HttpMethod.put,
      path: '/roles/$id/permissions',
      data: <String, dynamic>{'permissionIds': permissionIds},
    );
    return SettingsRole.fromJson(_requireMap(payload));
  }

  Future<List<SettingsPermission>> fetchPermissions() async {
    final payload = await _getPayload('/permissions');
    return _readList(
      payload,
    ).map(SettingsPermission.fromJson).toList(growable: false);
  }

  Future<Object?> _getPayload(String path) async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>(path);
      return _unwrapPayload(response.data);
    } on DioException catch (error) {
      throw _exceptionFromDio(error);
    }
  }

  Future<Object?> _sendPayload({
    required _HttpMethod method,
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = switch (method) {
        _HttpMethod.post => await apiClient.dio.post<Map<String, dynamic>>(
          path,
          data: data,
        ),
        _HttpMethod.patch => await apiClient.dio.patch<Map<String, dynamic>>(
          path,
          data: data,
        ),
        _HttpMethod.put => await apiClient.dio.put<Map<String, dynamic>>(
          path,
          data: data,
        ),
      };
      return _unwrapPayload(response.data);
    } on DioException catch (error) {
      throw _exceptionFromDio(error);
    }
  }

  Object? _unwrapPayload(Map<String, dynamic>? responseBody) {
    if (responseBody == null) {
      throw const SettingsRepositoryException(message: '后端响应为空');
    }

    final code = responseBody['code'];
    if (!_isSuccessCode(code)) {
      throw SettingsRepositoryException(
        code: code?.toString(),
        message: _readMessage(responseBody),
      );
    }

    return responseBody['data'];
  }

  bool _isSuccessCode(Object? code) {
    if (code == null || code == 0 || code == 200) {
      return true;
    }
    final text = code.toString();
    return text == '0' || text == '200' || text.endsWith('_SUCCESS');
  }

  SettingsRepositoryException _exceptionFromDio(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      return SettingsRepositoryException(
        code: responseData['code']?.toString(),
        message: _readMessage(responseData),
        statusCode: error.response?.statusCode,
      );
    }

    return SettingsRepositoryException(
      message: error.message ?? '请求失败',
      statusCode: error.response?.statusCode,
    );
  }

  String _readMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return '请求失败';
  }

  List<Map<String, dynamic>> _readList(Object? payload) {
    if (payload is Iterable) {
      return payload.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    throw const SettingsRepositoryException(message: '列表响应格式无效');
  }

  Map<String, dynamic> _requireMap(Object? payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }

    throw const SettingsRepositoryException(message: '对象响应格式无效');
  }
}

enum _HttpMethod { post, patch, put }

class SettingsRepositoryException implements Exception {
  const SettingsRepositoryException({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  bool get isForbidden => statusCode == 403 || code == 'FORBIDDEN';

  @override
  String toString() => 'SettingsRepositoryException: $message';
}
