/// API 配置文件
class ApiConfig {
  // 环境配置
  static const bool isDevelopment = false; // 开发环境：true, 生产环境：false

  // 服务器地址（已移除私人服务器地址，请配置为您自己的服务器）
  static const String testServerUrl = 'https://example.com';
  static const String productionServerUrl = 'https://example.com';

  // 当前服务器地址（根据环境自动选择）
  static String get baseUrl =>
      isDevelopment ? testServerUrl : productionServerUrl;

  // 已移除客户端证书及 mTLS 相关配置以防止敏感信息泄露

  // 广告配置: 在开源版本中默认禁用
  static const bool enableAdsOnEmulator = false;
  static const bool enableAppOpenAd = false;
  static const bool enableBannerAd = false;

  // (原广告单元 ID 已移除以避免泄露)

  // 超时配置
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);
}
