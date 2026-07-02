import 'package:dio/dio.dart';

/// 前端统一 HTTP 客户端入口。
///
/// 后续所有 API 调用应通过 Service / Repository 使用该客户端，避免业务页面
/// 直接散落 `Dio` 初始化、请求头和异常处理逻辑。
class ApiClient {
  ApiClient({Dio? dio}) : dio = dio ?? Dio();

  final Dio dio;
}
