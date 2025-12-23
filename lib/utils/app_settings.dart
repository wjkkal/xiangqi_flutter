import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置管理类
/// 负责保存和读取所有应用配置
class AppSettings {
  // 单例模式
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // SharedPreferences 实例
  SharedPreferences? _prefs;

  // 键常量
  static const String _keyAiEnabled = 'ai_enabled';
  static const String _keyAiDifficulty = 'ai_difficulty';
  static const String _keyHintDifficulty = 'hint_difficulty';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVolume = 'volume';
  static const String _keyBgmEnabled = 'bgm_enabled';
  static const String _keyBgmVolume = 'bgm_volume';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyAiMoveFirst = 'ai_move_first'; // AI 先行开关
  static const String _keyDeviceRegistered = 'device_registered'; // 设备注册状态
  static const String _keyRegId = 'reg_id'; // 用户注册UUID
  static const String _keyAppLaunchCount = 'app_launch_count'; // 应用启动次数

  // 默认值
  static const bool _defaultAiEnabled = true; // 默认启用AI对战
  static const int _defaultAiDifficulty = 1; // 默认难度1
  static const int _defaultHintDifficulty = 8; // 默认提示难度8
  static const bool _defaultSoundEnabled = true; // 默认启用音效
  static const double _defaultVolume = 0.6; // 默认音量60%
  static const bool _defaultBgmEnabled = false; // 默认关闭背景音乐
  static const double _defaultBgmVolume = 0.2;
  static const bool _defaultVibrationEnabled = true; // 默认启用震动
  static const bool _defaultAiMoveFirst = false; // 默认不启用AI先行

  /// 初始化 SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception('AppSettings not initialized. Call init() first.');
    }
  }

  // ==================== AI 设置 ====================

  /// 获取 AI 是否启用
  bool get aiEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyAiEnabled) ?? _defaultAiEnabled;
  }

  /// 设置 AI 是否启用
  Future<bool> setAiEnabled(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(_keyAiEnabled, value);
  }

  /// 获取 AI 难度
  int get aiDifficulty {
    _ensureInitialized();
    return _prefs!.getInt(_keyAiDifficulty) ?? _defaultAiDifficulty;
  }

  /// 设置 AI 难度
  Future<bool> setAiDifficulty(int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(_keyAiDifficulty, value);
  }

  /// 获取提示难度
  int get hintDifficulty {
    _ensureInitialized();
    return _prefs!.getInt(_keyHintDifficulty) ?? _defaultHintDifficulty;
  }

  /// 设置提示难度
  Future<bool> setHintDifficulty(int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(_keyHintDifficulty, value);
  }

  // ==================== 音效设置 ====================

  /// 获取音效是否启用
  bool get soundEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keySoundEnabled) ?? _defaultSoundEnabled;
  }

  /// 设置音效是否启用
  Future<bool> setSoundEnabled(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(_keySoundEnabled, value);
  }

  /// 获取音量
  double get volume {
    _ensureInitialized();
    return _prefs!.getDouble(_keyVolume) ?? _defaultVolume;
  }

  /// 设置音量
  Future<bool> setVolume(double value) async {
    _ensureInitialized();
    return await _prefs!.setDouble(_keyVolume, value);
  }

  // ==================== 背景音乐设置 ====================

  /// 获取背景音乐是否启用
  bool get bgmEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyBgmEnabled) ?? _defaultBgmEnabled;
  }

  /// 设置背景音乐是否启用
  Future<bool> setBgmEnabled(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(_keyBgmEnabled, value);
  }

  /// 获取背景音乐音量
  double get bgmVolume {
    _ensureInitialized();
    return _prefs!.getDouble(_keyBgmVolume) ?? _defaultBgmVolume;
  }

  /// 设置背景音乐音量
  Future<bool> setBgmVolume(double value) async {
    _ensureInitialized();
    return await _prefs!.setDouble(_keyBgmVolume, value);
  }

  // ==================== 震动设置 ====================

  /// 获取震动是否启用
  bool get vibrationEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyVibrationEnabled) ?? _defaultVibrationEnabled;
  }

  /// 获取 AI 先行设置（黑方先走）
  bool get aiMoveFirst {
    _ensureInitialized();
    return _prefs!.getBool(_keyAiMoveFirst) ?? _defaultAiMoveFirst;
  }

  /// 设置 AI 先行
  Future<bool> setAiMoveFirst(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(_keyAiMoveFirst, value);
  }

  /// 设置震动是否启用
  Future<bool> setVibrationEnabled(bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(_keyVibrationEnabled, value);
  }

  // ==================== 设备注册状态 ====================

  /// 获取设备注册状态 (0-未注册, 1-已注册)
  int get deviceRegistered {
    _ensureInitialized();
    return _prefs!.getInt(_keyDeviceRegistered) ?? 0;
  }

  /// 设置设备注册状态
  Future<bool> setDeviceRegistered(int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(_keyDeviceRegistered, value);
  }

  /// 获取用户注册UUID
  String? get regId {
    _ensureInitialized();
    return _prefs!.getString(_keyRegId);
  }

  /// 获取应用启动次数
  int get appLaunchCount {
    _ensureInitialized();
    return _prefs!.getInt(_keyAppLaunchCount) ?? 0;
  }

  /// 增加应用启动次数（每次应用 cold start 时调用）
  Future<bool> incrementAppLaunchCount() async {
    _ensureInitialized();
    final current = appLaunchCount;
    return await _prefs!.setInt(_keyAppLaunchCount, current + 1);
  }

  /// 设置用户注册UUID
  Future<bool> setRegId(String value) async {
    _ensureInitialized();
    return await _prefs!.setString(_keyRegId, value);
  }

  // ==================== 批量操作 ====================

  /// 保存所有设置
  Future<void> saveAllSettings({
    required bool aiEnabled,
    required int aiDifficulty,
    required int hintDifficulty,
    required bool soundEnabled,
    required double volume,
    required bool bgmEnabled,
    required double bgmVolume,
    required bool vibrationEnabled,
    // 新增：是否启用 AI 先行
    bool aiMoveFirst = false,
  }) async {
    await Future.wait([
      setAiEnabled(aiEnabled),
      setAiDifficulty(aiDifficulty),
      setHintDifficulty(hintDifficulty),
      setSoundEnabled(soundEnabled),
      setVolume(volume),
      setBgmEnabled(bgmEnabled),
      setBgmVolume(bgmVolume),
      setVibrationEnabled(vibrationEnabled),
      setAiMoveFirst(aiMoveFirst),
    ]);
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    await saveAllSettings(
      aiEnabled: _defaultAiEnabled,
      aiDifficulty: _defaultAiDifficulty,
      hintDifficulty: _defaultHintDifficulty,
      soundEnabled: _defaultSoundEnabled,
      volume: _defaultVolume,
      bgmEnabled: _defaultBgmEnabled,
      bgmVolume: _defaultBgmVolume,
      vibrationEnabled: _defaultVibrationEnabled,
    );
  }

  /// 清除所有设置
  Future<bool> clearAll() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }
}
