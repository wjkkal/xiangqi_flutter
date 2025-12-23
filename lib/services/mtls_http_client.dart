import 'package:flutter/foundation.dart';

/// mTLS 客户端已在开源版本中移除。保留一个安全的占位实现以避免编译错误。
enum MtlsConnectionStatus { notInitialized, removed }

class MtlsHttpClient {
  static MtlsHttpClient? _instance;
  MtlsHttpClient._();

  static MtlsHttpClient get instance {
    _instance ??= MtlsHttpClient._();
    return _instance!;
  }

  MtlsConnectionStatus get status => MtlsConnectionStatus.removed;

  String? get lastError => 'mTLS 功能已移除';

  Future<void> initialize() async {
    debugPrint('mTLS 初始化已移除（开源版）');
  }

  Future<Map<String, dynamic>> testConnection() async {
    return {
      'success': false,
      'message': 'mTLS 功能已移除',
    };
  }

  /// 提供兼容的 HTTP 方法占位实现，返回公开的 Map 结构: { 'statusCode': int, 'body': String }
  Future<Map<String, Object>> get(String endpoint) async {
    debugPrint('HTTP GET 已被禁用（开源版）：$endpoint');
    return {'statusCode': 404, 'body': 'Not available'};
  }

  Future<Map<String, Object>> post(String endpoint, {Object? body}) async {
    debugPrint('HTTP POST 已被禁用（开源版）：$endpoint');
    return {'statusCode': 404, 'body': 'Not available'};
  }

  Future<Map<String, Object>> put(String endpoint, {Object? body}) async {
    debugPrint('HTTP PUT 已被禁用（开源版）：$endpoint');
    return {'statusCode': 404, 'body': 'Not available'};
  }

  Future<Map<String, Object>> delete(String endpoint) async {
    debugPrint('HTTP DELETE 已被禁用（开源版）：$endpoint');
    return {'statusCode': 404, 'body': 'Not available'};
  }

  void dispose() {}
}

/// 超时异常占位
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
