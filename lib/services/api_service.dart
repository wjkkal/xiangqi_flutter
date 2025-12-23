import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'mtls_http_client.dart';

/// API 服务示例
/// 演示如何使用 MtlsHttpClient 调用后端接口
class ApiService {
  final MtlsHttpClient _client = MtlsHttpClient.instance;

  /// 测试 mTLS 连接（调用测试接口）
  ///
  /// 返回示例:
  /// ```dart
  /// {
  ///   "success": true,
  ///   "message": "mTLS 验证成功! 只有持有有效客户端证书的App才能看到此消息。"
  /// }
  /// ```
  Future<Map<String, dynamic>> testMtlsConnection() async {
    try {
      final result = await _client.testConnection();

      if (result['success']) {
        // 解析 JSON 响应
        final responseBody = jsonDecode(result['body']);
        return {
          'success': true,
          'message': responseBody['message'] ?? '连接成功',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': result['message'],
        };
      }
    } catch (e) {
      debugPrint('测试 mTLS 连接异常: $e');
      return {
        'success': false,
        'message': '连接测试失败: $e',
      };
    }
  }

  /// 示例：GET 请求
  ///
  /// 使用方式:
  /// ```dart
  /// final result = await apiService.getData('/api/v1/some-endpoint');
  /// ```
  Future<Map<String, dynamic>> getData(String endpoint) async {
    try {
      final response = await _client.get(endpoint);

      // 兼容 mTLS 占位返回 Map { 'statusCode', 'body' }
      final statusCode = (response['statusCode'] as int?) ?? 0;
      final body = (response['body'] as String?) ?? '';

      if (statusCode == 200) {
        final data = jsonDecode(body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP $statusCode: $body',
        };
      }
    } catch (e) {
      debugPrint('GET 请求异常: $e');
      return {
        'success': false,
        'message': '请求失败: $e',
      };
    }
  }

  /// 示例：POST 请求
  ///
  /// 使用方式:
  /// ```dart
  /// final result = await apiService.postData(
  ///   '/api/v1/some-endpoint',
  ///   {'key': 'value'},
  /// );
  /// ```
  Future<Map<String, dynamic>> postData(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.post(
        endpoint,
        body: jsonEncode(data),
      );

      final statusCode = (response['statusCode'] as int?) ?? 0;
      final body = (response['body'] as String?) ?? '';

      if (statusCode == 200 || statusCode == 201) {
        final responseData = jsonDecode(body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP $statusCode: $body',
        };
      }
    } catch (e) {
      debugPrint('POST 请求异常: $e');
      return {
        'success': false,
        'message': '请求失败: $e',
      };
    }
  }

  /// 示例：PUT 请求
  Future<Map<String, dynamic>> putData(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put(
        endpoint,
        body: jsonEncode(data),
      );

      final statusCode = (response['statusCode'] as int?) ?? 0;
      final body = (response['body'] as String?) ?? '';

      if (statusCode == 200) {
        final responseData = jsonDecode(body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP $statusCode: $body',
        };
      }
    } catch (e) {
      debugPrint('PUT 请求异常: $e');
      return {
        'success': false,
        'message': '请求失败: $e',
      };
    }
  }

  /// 示例：DELETE 请求
  Future<Map<String, dynamic>> deleteData(String endpoint) async {
    try {
      final response = await _client.delete(endpoint);

      final statusCode = (response['statusCode'] as int?) ?? 0;
      final body = (response['body'] as String?) ?? '';

      if (statusCode == 200 || statusCode == 204) {
        return {
          'success': true,
          'message': '删除成功',
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP $statusCode: $body',
        };
      }
    } catch (e) {
      debugPrint('DELETE 请求异常: $e');
      return {
        'success': false,
        'message': '请求失败: $e',
      };
    }
  }

  /// 用户信息注册接口
  ///
  /// 参数:
  /// - regId: 客户端生成的用户注册UUID (必填)
  /// - deviceId: 设备唯一标识符
  /// - androidId: Android设备ID
  /// - platformId: 平台ID (0-iOS, 1-Android, 2-PC, 3-Web)
  /// - countryCode: 国家代码
  ///
  /// 返回示例:
  /// 成功（新用户）: "1"
  /// 设备已存在（老用户）: "0"
  Future<Map<String, dynamic>> registerUser({
    required String regId,
    required String deviceId,
    required String androidId,
    required int platformId,
    required String countryCode,
  }) async {
    try {
      // 开源版不执行注册请求，返回本地成功状态
      debugPrint('🔒 注册接口在开源版中被禁用 — 不会向服务器发送设备信息');
      return {
        'success': true,
        'isNewUser': false,
        'regId': regId,
        'message': '本地模式：未上报服务器',
      };
    } catch (e) {
      debugPrint('❌ 用户注册异常: $e');
      return {
        'success': false,
        'message': '注册失败: $e',
      };
    }
  }

  /// 用户登录日志接口
  ///
  /// 参数:
  /// - uid: 用户UUID (已注册则传reg_id,未注册则传"未注册+随机字母")
  /// - loginType: 登录类型 (1-账号, 2-手机, 3-微信, 4-Guest)
  /// - deviceId: 设备唯一标识符
  /// - loginDevice: 登录设备信息
  /// - os: 操作系统
  /// - appVer: APP版本号
  /// - success: 登录是否成功
  /// - countryCode: 国家代码 (可选)
  Future<Map<String, dynamic>> logUserLogin({
    required String uid,
    required int loginType,
    required String deviceId,
    required String loginDevice,
    required String os,
    required String appVer,
    required bool success,
    String? countryCode,
  }) async {
    try {
      // 开源版不上传登录日志，返回本地成功
      debugPrint('🔒 登录日志上报在开源版被禁用');
      return {
        'success': true,
        'message': '本地模式：登录日志未上报',
      };
    } catch (e) {
      debugPrint('❌ 登录日志异常: $e');
      return {
        'success': false,
        'message': '登录日志记录失败: $e',
      };
    }
  }
}
