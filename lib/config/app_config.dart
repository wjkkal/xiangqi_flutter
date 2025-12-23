import 'api_config.dart';

/// 应用级别的开关和配置
///
/// 将与环境相关的调试/特性开关集中在此处，方便测试与发布时统一管理。
class AppConfig {
  // 当为开发环境时默认启用调试按钮，发布环境下为 false
  static const bool showDebugButtons = ApiConfig.isDevelopment;

  // 控制是否在设置/面板中显示 AI 相关的调试控件
  // 改动：不再由 ApiConfig.isDevelopment 控制 — 始终显示 AI 调试控件
  // 如果需要为生产/测试/开发不同策略，请将其改为运行时配置或枚举环境管理
  static const bool showAIDebugButtons = true;
}
