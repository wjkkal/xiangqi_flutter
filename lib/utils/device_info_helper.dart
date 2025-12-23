import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:system_info_plus/system_info_plus.dart';
import '../generated/shouji_model_map.dart';

class DeviceInfoResult {
  final String platform;
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final String countryCode;
  final List<String> additionalInfo;

  DeviceInfoResult({
    required this.platform,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    required this.countryCode,
    required this.additionalInfo,
  });
}

Future<DeviceInfoResult> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin(); // DeviceInfoPlugin 实例，用于获取设备信息
  String deviceName = '未知'; // 设备名称（例如用户设定的设备名），默认 '未知'
  String deviceModel = '未知'; // 设备型号（如 iPhone X、Pixel 4），默认 '未知'
  String osVersion = '未知'; // 操作系统版本（如 Android 11、iOS 14），默认 '未知'
  String platform = '未知'; // 平台类型（例如 Android、iOS、Web），默认 '未知'
  String countryCode = '未知'; // 国家/地区代码（通常从 Locale 提取），默认 '未知'
  List<String> additionalInfo = []; // 存放额外设备信息的字符串列表

  try {
    if (kIsWeb) {
      platform = 'Web';
      final webInfo = await deviceInfo.webBrowserInfo;
      deviceName = webInfo.browserName.name;
      deviceModel = webInfo.platform ?? '未知';
      osVersion = webInfo.userAgent ?? '未知';
      countryCode = '未知';
    } else if (Platform.isAndroid) {
      platform = 'Android';
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.brand;
      deviceModel = androidInfo.model;
      osVersion = 'Android ${androidInfo.version.release}';
      countryCode = Platform.localeName.split('_').last;
      final marketName = shoujiName(androidInfo.model);
      final androidId = androidInfo.fingerprint;
      final cpuAbi = androidInfo.supportedAbis.isNotEmpty
          ? androidInfo.supportedAbis.first
          : '未知';
      final allAbis = androidInfo.supportedAbis.join(', ');
      String cpuModel = '未知';
      String cpuCores = '未知';
      String totalMemory = '未知';
      String availableMemory = '未知';
      try {
        final cpuInfoFile = File('/proc/cpuinfo');
        if (await cpuInfoFile.exists()) {
          final cpuInfoContent = await cpuInfoFile.readAsString();
          final lines = cpuInfoContent.split('\n');
          for (var line in lines) {
            if (line.toLowerCase().contains('hardware') ||
                line.toLowerCase().contains('model name')) {
              final parts = line.split(':');
              if (parts.length > 1) {
                cpuModel = parts[1].trim();
                break;
              }
            }
          }
          int coreCountFromFile = 0;
          for (var line in lines) {
            if (line.startsWith('processor')) {
              coreCountFromFile++;
            }
          }
          if (coreCountFromFile > 0) {
            cpuCores = '$coreCountFromFile核心';
          }
        }
        try {
          final physMem = await SystemInfoPlus.physicalMemory;
          if (physMem != null && physMem > 0) {
            final memGB = (physMem / 1024.0).toStringAsFixed(2);
            totalMemory = '$physMem MB ($memGB GB)';
          }
        } catch (e, st) {
          debugPrint('getDeviceInfo: physicalMemory error: $e\n$st');
        }
        final memInfoFile = File('/proc/meminfo');
        if (await memInfoFile.exists()) {
          final memInfoContent = await memInfoFile.readAsString();
          final lines = memInfoContent.split('\n');
          for (var line in lines) {
            if (line.startsWith('MemTotal:') && totalMemory == '未知') {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length > 1) {
                final memKB = int.tryParse(parts[1]) ?? 0;
                final memMB = (memKB / 1024).toStringAsFixed(0);
                final memGB = (memKB / 1024 / 1024).toStringAsFixed(2);
                totalMemory = '$memMB MB ($memGB GB)';
              }
            } else if (line.startsWith('MemAvailable:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length > 1) {
                final memKB = int.tryParse(parts[1]) ?? 0;
                final memMB = (memKB / 1024).toStringAsFixed(0);
                final memGB = (memKB / 1024 / 1024).toStringAsFixed(2);
                availableMemory = '$memMB MB ($memGB GB)';
              }
            }
          }
        }
      } catch (e, st) {
        debugPrint('getDeviceInfo (outer): $e\n$st');
      }
      additionalInfo = [
        '市场名称: $marketName',
        'Android ID: $androidId',
        'SDK: ${androidInfo.version.sdkInt}',
        '制造商: ${androidInfo.manufacturer}',
        '设备: ${androidInfo.device}',
        '硬件: ${androidInfo.hardware}',
        'CPU型号: $cpuModel',
        'CPU核心: $cpuCores',
        'CPU架构: $cpuAbi',
        '支持的ABI: $allAbis',
        '总内存: $totalMemory',
        '可用内存: $availableMemory',
        '物理设备: ${androidInfo.isPhysicalDevice ? "是" : "否"}',
        '32位模式: ${androidInfo.supported32BitAbis.isNotEmpty ? "支持" : "不支持"}',
        '64位模式: ${androidInfo.supported64BitAbis.isNotEmpty ? "支持" : "不支持"}',
      ];
    } else if (Platform.isIOS) {
      platform = 'iOS';
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
      deviceModel = iosInfo.model;
      osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      countryCode = Platform.localeName.split('_').last;
      final idfv = iosInfo.identifierForVendor ?? '未知';
      additionalInfo = [
        'IDFV: $idfv',
        '设备类型: ${iosInfo.utsname.machine}',
        '物理设备: ${iosInfo.isPhysicalDevice ? "是" : "否"}',
      ];
    } else if (Platform.isWindows) {
      platform = 'Windows';
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceName = windowsInfo.computerName;
      deviceModel = 'Windows PC';
      osVersion = windowsInfo.productName;
      countryCode = Platform.localeName.split('_').last;
      additionalInfo = [
        '版本号: ${windowsInfo.buildNumber}',
      ];
    } else if (Platform.isLinux) {
      platform = 'Linux';
      final linuxInfo = await deviceInfo.linuxInfo;
      deviceName = linuxInfo.name;
      deviceModel = linuxInfo.prettyName;
      osVersion = linuxInfo.version ?? '未知';
      countryCode = Platform.localeName.split('_').last;
    } else if (Platform.isMacOS) {
      platform = 'macOS';
      final macInfo = await deviceInfo.macOsInfo;
      deviceName = macInfo.computerName;
      deviceModel = macInfo.model;
      osVersion = 'macOS ${macInfo.osRelease}';
      countryCode = Platform.localeName.split('_').last;
    }
  } catch (e) {
    countryCode = '未知';
  }

  return DeviceInfoResult(
    platform: platform,
    deviceName: deviceName,
    deviceModel: deviceModel,
    osVersion: osVersion,
    countryCode: countryCode,
    additionalInfo: additionalInfo,
  );
}
