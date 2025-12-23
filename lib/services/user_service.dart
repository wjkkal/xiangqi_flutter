import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_settings.dart';
import '../utils/device_info_helper.dart';

/// 用户服务
/// 负责用户注册和登录日志记录
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final AppSettings _settings = AppSettings();

  /// 获取APP版本号
  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      debugPrint('获取APP版本号失败: $e');
      return '1.0.0';
    }
  }

  /// 异步注册用户设备
  /// 此方法不阻塞APP运行,即使失败也不影响
  Future<void> registerDeviceAsync() async {
    try {
      // 检查是否已注册
      final isRegistered = _settings.deviceRegistered == 1;
      if (isRegistered) {
        debugPrint('✅ 设备已注册,跳过注册流程');
        return;
      }

      debugPrint('📝 开始设备注册...');

      // 获取或生成 reg_id
      String? regId = _settings.regId;
      if (regId == null || regId.isEmpty) {
        // 生成新的 UUID
        const uuid = Uuid();
        regId = uuid.v4();
        await _settings.setRegId(regId);
        debugPrint('🆔 生成新的 reg_id: $regId');
      }

      // 获取设备信息
      final deviceInfo = await getDeviceInfo();
      final androidId = deviceInfo.additionalInfo
          .firstWhere(
            (info) => info.startsWith('Android ID:'),
            orElse: () => 'Android ID: UNKNOWN',
          )
          .split(':')[1]
          .trim();

      if (androidId == 'UNKNOWN') {
        debugPrint('⚠️ 无法获取Android ID,设备注册失败');
        await _settings.setDeviceRegistered(0);
        return;
      }

      // 开源版不向后端注册设备，仅在本地记录已注册状态
      await _settings.setDeviceRegistered(1);
      debugPrint('✅ 已在本地标记设备为已注册 (未上报服务器): $regId');
    } catch (e) {
      debugPrint('❌ 设备注册异常: $e');
      await _settings.setDeviceRegistered(0);
    }
  }

  /// 异步记录登录日志
  /// 此方法不阻塞APP运行,即使失败也不影响
  Future<void> logLoginAsync() async {
    try {
      debugPrint('📝 开始记录登录日志...');

      // 获取设备信息
      final deviceInfo = await getDeviceInfo();

      // 获取 reg_id (每次都使用本地保存的 reg_id)
      final regId = _settings.regId;

      if (regId == null || regId.isEmpty) {
        debugPrint('⚠️ reg_id 不存在,跳过登录日志记录');
        return;
      }

      // 构建登录设备信息
      final appVersion = await _getAppVersion();
      final loginDevice = '${deviceInfo.platform}; '
          '${deviceInfo.deviceModel}; '
          '${deviceInfo.osVersion}; '
          'XiangqiApp/$appVersion; '
          '${deviceInfo.additionalInfo.join('; ')}';

      // 开源版不上传登录日志，仅在本地记录（如需可写入本地）
      debugPrint('✅ 本地记录登录日志（未上报服务器）: $loginDevice');
    } catch (e) {
      debugPrint('❌ 登录日志记录异常: $e');
    }
  }

  /// 获取本地保存的 reg_id
  /// 用于其他服务调用(如反馈接口)
  Future<String?> getRegId() async {
    return _settings.regId;
  }

  /// 初始化用户服务
  /// 在APP启动时调用,处理注册和登录日志
  Future<void> initializeOnAppStart() async {
    // 异步执行,不阻塞APP启动
    Future.microtask(() async {
      try {
        // 1. 先尝试注册设备
        await registerDeviceAsync();

        // 2. 记录登录日志
        await logLoginAsync();
      } catch (e) {
        debugPrint('❌ 用户服务初始化异常: $e');
      }
    });
  }
}
