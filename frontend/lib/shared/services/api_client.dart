import 'dart:async';

import 'package:dio/dio.dart';

import '../../modules/auth/storage/token_storage.dart';

typedef UnauthorizedCallback = FutureOr<void> Function();
typedef RefreshDataCallback =
    FutureOr<void> Function(Map<String, dynamic> data);

/// 前端统一 HTTP 客户端入口。
///
/// 后续所有 API 调用应通过 Service / Repository 使用该客户端，避免业务页面
/// 直接散落 `Dio` 初始化、请求头和异常处理逻辑。
class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
    this.onUnauthorized,
    this.onRefreshData,
    String baseUrl = defaultBaseUrl,
  }) : dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)),
       tokenStorage = tokenStorage ?? TokenStorage() {
    if (this.dio.options.baseUrl.isEmpty) {
      this.dio.options.baseUrl = baseUrl;
    }
    _installAuthInterceptor();
  }

  static const defaultBaseUrl = 'http://localhost:3000/api';
  static const skipAuthExtraKey = 'skipAuth';

  static const _retriedExtraKey = 'authRetried';

  final Dio dio;
  final TokenStorage tokenStorage;
  UnauthorizedCallback? onUnauthorized;
  RefreshDataCallback? onRefreshData;

  Future<void>? _refreshFuture;
  bool _unauthorizedNotified = false;

  /// 标记进入新的有效认证周期。
  ///
  /// 登录成功、冷启动 refresh 成功、拦截器 refresh 成功后都需要调用该方法，
  /// 避免上一轮 refresh 失败留下的 unauthorized 闩锁阻止后续周期的回调。
  void markAuthenticated() {
    resetUnauthorizedNotification();
  }

  /// 重置 unauthorized 通知闩锁。
  ///
  /// 该方法只重置通知状态，不读写 token，也不会触发任何网络请求。
  void resetUnauthorizedNotification() {
    _unauthorizedNotified = false;
  }

  void _installAuthInterceptor() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final accessToken = tokenStorage.accessToken;
          final skipAuth = options.extra[skipAuthExtraKey] == true;
          if (!skipAuth &&
              accessToken != null &&
              accessToken.isNotEmpty &&
              !_isLoginOrRefresh(options.path)) {
            // Authorization 只注入内存 access token，不从磁盘反查，确保短期凭证
            // 不会因为请求拦截器而被写入普通持久化介质。
            options.headers['authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (!_shouldRefresh(error)) {
            handler.next(error);
            return;
          }

          try {
            await _refreshTokens();
          } catch (_) {
            await _handleRefreshFailure();
            handler.next(error);
            return;
          }

          try {
            final response = await _replayRequest(error.requestOptions);
            handler.resolve(response);
          } on DioException catch (replayError) {
            // refresh 成功代表认证周期仍然有效；重放失败属于原业务请求结果，
            // 必须原样交回调用方，不能清理 token 或触发 unauthorized。
            handler.next(replayError);
          }
        },
      ),
    );
  }

  bool _shouldRefresh(DioException error) {
    final requestOptions = error.requestOptions;
    return error.response?.statusCode == 401 &&
        requestOptions.extra[skipAuthExtraKey] != true &&
        requestOptions.extra[_retriedExtraKey] != true &&
        !_isLoginOrRefresh(requestOptions.path);
  }

  Future<void> _refreshTokens() {
    final runningRefresh = _refreshFuture;
    if (runningRefresh != null) {
      return runningRefresh;
    }

    final nextRefresh = _performRefresh();
    _refreshFuture = nextRefresh.whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<void> _performRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        message: 'Refresh token is missing',
      );
    }

    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: <String, dynamic>{'refreshToken': refreshToken},
      options: Options(extra: const <String, Object>{skipAuthExtraKey: true}),
    );
    final data = _unwrapRefreshData(response.data);
    final accessToken = data['accessToken'];
    final nextRefreshToken = data['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        nextRefreshToken is! String ||
        nextRefreshToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Refresh response token data is invalid',
      );
    }

    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
    );
    markAuthenticated();
    await onRefreshData?.call(data);
  }

  Future<Response<dynamic>> _replayRequest(RequestOptions requestOptions) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    final accessToken = tokenStorage.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['authorization'] = 'Bearer $accessToken';
    }

    return dio.fetch<dynamic>(
      requestOptions.copyWith(
        headers: headers,
        extra: <String, dynamic>{
          ...requestOptions.extra,
          _retriedExtraKey: true,
        },
      ),
    );
  }

  Future<void> _handleRefreshFailure() async {
    await tokenStorage.clear();
    if (_unauthorizedNotified) {
      return;
    }
    _unauthorizedNotified = true;
    await onUnauthorized?.call();
  }

  Map<String, dynamic> _unwrapRefreshData(Map<String, dynamic>? responseBody) {
    if (responseBody == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        message: 'Refresh response body is empty',
      );
    }

    final data = responseBody['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw DioException(
      requestOptions: RequestOptions(path: '/auth/refresh'),
      message: 'Refresh response data is invalid',
    );
  }

  bool _isLoginOrRefresh(String path) {
    final normalizedPath = Uri.parse(path).path;
    return normalizedPath.endsWith('/auth/login') ||
        normalizedPath.endsWith('/auth/refresh');
  }
}
