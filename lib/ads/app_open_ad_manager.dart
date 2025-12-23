/// 广告管理器在开源版中已移除，保留占位类以避免引用错误。
class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  Future<void> loadAd() async {
    // no-op
  }

  Future<void> showAdIfAvailable() async {
    // no-op
  }

  void dispose() {}
}
