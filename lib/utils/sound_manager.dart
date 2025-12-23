import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 音效管理器，负责管理游戏中的所有音效
class SoundManager with WidgetsBindingObserver {
  // 单例模式
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  /// 音效播放器
  late final AudioPlayer _player;

  /// 背景音乐播放器
  late final AudioPlayer _bgmPlayer;

  /// 初始化完成标志
  bool _isInitialized = false;

  /// 是否静音
  bool _isMuted = false;

  /// 音量 (0.0 - 1.0) - 默认设置为最大音量
  double _volume = 1.0;

  /// 背景音乐是否启用
  bool _bgmEnabled = false;

  /// 震动是否启用
  bool _vibrationEnabled = true;

  /// 背景音乐音量 (0.0 - 1.0)
  double _bgmVolume = 0.5;

  /// 构造函数
  SoundManager._internal();

  /// 初始化播放器 - 必须在使用前调用
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('🔊 SoundManager 已经初始化,跳过');
      return;
    }

    debugPrint('🔊 开始初始化 SoundManager...');

    // 为音效创建一个新的播放器实例
    _player = AudioPlayer();
    // 设置音效播放器 - 使用低延迟模式,允许同时播放
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setVolume(1.0);
    await _player.setReleaseMode(ReleaseMode.stop);
    // 设置音频上下文 - 不请求音频焦点,与背景音乐混音
    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // 不请求音频焦点,允许与背景音乐混音
        ),
      ),
    );

    // 为背景音乐创建一个新的播放器实例
    _bgmPlayer = AudioPlayer();
    // 设置背景音乐播放器 - 使用媒体播放器模式
    await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await _bgmPlayer.setVolume(_bgmVolume);
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    // 设置音频上下文 - 获取音频焦点并持续播放
    await _bgmPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain, // 持续获取音频焦点
        ),
      ),
    );

    _isInitialized = true;
    // 注册应用生命周期监听，以便在切换后台/前台时暂停/恢复 BGM
    try {
      WidgetsBinding.instance.addObserver(this);
      debugPrint('🔊 SoundManager 已注册生命周期监听');
    } catch (e) {
      debugPrint('⚠️ 注册生命周期监听失败: $e');
    }
    debugPrint('✅ SoundManager 初始化完成');
    debugPrint('   音效播放器音量: 100%');
    debugPrint('   背景音乐播放器支持混音');
  }

  /// 获取静音状态
  bool get isMuted => _isMuted;

  /// 获取音量
  double get volume => _volume;

  /// 获取背景音乐是否启用
  bool get bgmEnabled => _bgmEnabled;

  /// 获取震动是否启用
  bool get vibrationEnabled => _vibrationEnabled;

  /// 获取背景音乐音量
  double get bgmVolume => _bgmVolume;

  /// 设置静音状态
  void setMuted(bool muted) {
    _isMuted = muted;
    debugPrint('🔊 音效${muted ? "静音" : "开启"}');
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    final newVolume = volume.clamp(0.0, 1.0);
    _volume = newVolume;
    // 在 lowLatency 模式下，音量应在 play 调用之前设置
    // 因此，我们从这里移除 setVolume 调用，以避免不必要/潜在冲突的调用
    // await _player.setVolume(_volume);
    debugPrint('🔊 音量设置为: ${(_volume * 100).toInt()}%');
  }

  /// 背景音乐功能已移除（开源版）。保留设置接口但为 no-op。
  Future<void> setBgmEnabled(bool enabled) async {
    debugPrint('🎵 背景音乐功能在开源版已移除');
    _bgmEnabled = false;
  }

  /// 设置震动开关
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    debugPrint('📳 震动${enabled ? "已启用" : "已禁用"}');
  }

  /// 设置背景音乐音量
  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    await _bgmPlayer.setVolume(_bgmVolume);
    debugPrint('🎵 背景音乐音量设置为: ${(_bgmVolume * 100).toInt()}%');
  }

  /// 播放背景音乐（开源版已移除）
  Future<void> playBgm() async {
    debugPrint('🎵 playBgm 被调用，但背景音乐功能在开源版已移除');
  }

  /// 停止/暂停/恢复 背景音乐 - 均为 no-op（已移除）
  Future<void> stopBgm() async {
    debugPrint('🎵 stopBgm 被调用，但背景音乐功能在开源版已移除');
  }

  Future<void> pauseBgm() async {
    debugPrint('🎵 pauseBgm 被调用，但背景音乐功能在开源版已移除');
  }

  Future<void> resumeBgm() async {
    debugPrint('🎵 resumeBgm 被调用，但背景音乐功能在开源版已移除');
  }

  /// 播放落子音效
  Future<void> playMove() async {
    await _playSound('sounds/xiangqiluozi.mp3', '落子');
  }

  /// 播放吃子音效（如果有的话，暂时使用落子音效）
  Future<void> playCapture() async {
    // 使用专门的吃子音效文件
    await _playSound('sounds/capture.mp3', '吃子');
  }

  /// 播放将军音效
  Future<void> playCheck() async {
    await _playSound('sounds/jiangjun.mp3', '将军');
  }

  /// 播放将死音效（如果有的话，暂时使用落子音效）
  Future<void> playCheckmate() async {
    await _playSound('sounds/xiangqiluozi.mp3', '将死');
  }

  /// 播放非法移动音效（如果有的话，暂时使用落子音效）
  Future<void> playIllegal() async {
    await _playSound('sounds/xiangqiluozi.mp3', '非法移动');
  }

  /// 内部方法：播放指定音效
  Future<void> _playSound(String assetPath, String soundName) async {
    if (_isMuted || _volume <= 0.0) {
      debugPrint('🔇 音效已静音或音量为0，跳过播放: $soundName');
      return;
    }

    try {
      // debugPrint('🔊 准备播放音效: $soundName');
      // debugPrint('   文件路径: $assetPath');
      // debugPrint('   当前音量: ${(_volume * 100).toInt()}%');

      // 停止之前的音效播放
      await _player.stop();

      // 设置音量(lowLatency模式下需要先设置音量)
      await _player.setVolume(_volume);

      // debugPrint('   开始播放...');

      // 播放音效
      await _player.play(AssetSource(assetPath));

      // debugPrint('✅ 音效播放命令已发送: $soundName');
      // 触发震动（若启用）
      try {
        if (_vibrationEnabled) {
          HapticFeedback.vibrate();
        }
      } catch (e) {
        debugPrint('⚠️ 触发震动失败: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 音效播放失败: $soundName');
      debugPrint('   错误: $e');
      debugPrint('   堆栈: $stackTrace');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _player.stop();
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      debugPrint('⚠️ 取消注册生命周期监听失败: $e');
    }
    await _player.dispose();
    await _bgmPlayer.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用切到后台/暂停时，Pause；恢复时 Resume
    if (state == AppLifecycleState.paused) {
      pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      resumeBgm();
    }
  }
}
