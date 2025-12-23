import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'widgets/game_board.dart';
import 'controllers/game_controller.dart';
import 'utils/sound_manager.dart';
import 'widgets/bottom_action_bar.dart';
import 'dialogs/settings_dialog.dart';
import 'eleeye/first_move_book.dart';
import 'dialogs/evaluation_result_dialog.dart';
import 'dialogs/engine_info_dialog.dart';
import 'utils/app_settings.dart';
import 'dialogs/game_info_dialog.dart';

import 'config/app_config.dart';
import 'config/api_config.dart';
import 'services/user_service.dart';
import 'utils/snackbar_helper.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化应用设置
  await AppSettings().init();
  // 记录一次冷启动（用于控制前几次不展示/加载广告的策略）
  try {
    await AppSettings().incrementAppLaunchCount();
    debugPrint('📈 应用启动计数: ${AppSettings().appLaunchCount}');
  } catch (e) {
    debugPrint('⚠️ 无法更新应用启动计数: $e');
  }

  // 初始化音效管理器
  await SoundManager().init();

  // 已移除针对 mTLS 和广告的后台初始化（为开源发布删除外部网络与广告调用）
  _initializeUserServiceAsync();

  // 设置只允许竖屏模式
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 配置系统 UI 覆盖层样式 (避免使用已弃用的 API)
  // 使用透明状态栏和导航栏，让 Flutter 处理边衬区
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const XiangqiApp());
}

/// 异步初始化用户服务（后台执行）
void _initializeUserServiceAsync() {
  Future.microtask(() async {
    try {
      debugPrint('========== 初始化用户服务 ==========');
      await UserService().initializeOnAppStart();
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('⚠️ 用户服务初始化异常: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  });
}

/// 中国象棋游戏的主应用程序组件
///
/// 这是应用程序的根组件，设置了 MaterialApp 并配置了
/// 中国主题样式以及导航到主游戏页面。
///
/// 应用程序使用棕色配色方案来匹配传统中国象棋的
/// 美学效果，并采用 Material Design 3 组件。
class XiangqiApp extends StatelessWidget {
  const XiangqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '中国象棋',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const XiangqiGamePage(),
    );
  }
}

/// 一个表示中国象棋主游戏页面的有状态组件（StatefulWidget）。
///
/// 该组件作为主要的游戏界面，负责创建并管理棋盘视图、棋子移动和游戏逻辑的交互。
/// 它在其状态类中维护可变状态，例如当前棋局位置、轮次、走步记录、AI 与音效设置以及游戏状态等。
///
/// 该组件遵循 Flutter 的 StatefulWidget 模式，以便在游戏进行过程中响应用户交互并更新界面。
/// 常见职责包括：初始化/重置棋局、处理悔棋、与 AI 协同工作、展示提示与信息对话框以及管理音效与评估结果。
class XiangqiGamePage extends StatefulWidget {
  const XiangqiGamePage({super.key});

  @override
  State<XiangqiGamePage> createState() => _XiangqiGamePageState();
}

class _XiangqiGamePageState extends State<XiangqiGamePage> {
  // 配置变量 - 初始值将从本地存储加载
  late bool _aiEnabled;
  late int _aiDifficulty;
  late int _hintDifficulty;
  late bool _soundEnabled;
  late double _volume;
  late bool _bgmEnabled;
  late double _bgmVolume;
  late bool _vibrationEnabled;
  late bool _aiMoveFirst;
  // 复用的随机数生成器，避免每次新建 Random 导致可重复性或相同种子问题
  final Random _rand = Random();
  GameController? _gameController;

  // 开屏广告相关逻辑已在开源版中移除
  @override
  void initState() {
    super.initState();
    _loadSettings();
    // 开屏广告初始化已移除
  }

  @override
  void dispose() {
    // 广告生命周期监听器已移除（开源版）。
    super.dispose();
  }

  /// 从本地存储加载设置
  Future<void> _loadSettings() async {
    final settings = AppSettings();
    setState(() {
      _aiEnabled = settings.aiEnabled;
      _aiDifficulty = settings.aiDifficulty;
      _hintDifficulty = settings.hintDifficulty;
      // 新行为：音效是否启用由音量是否为 0 决定
      _volume = settings.volume;
      _soundEnabled = _volume > 0;
      _bgmVolume = settings.bgmVolume;
      _bgmEnabled = _bgmVolume > 0;
      // 震动设置
      _vibrationEnabled = settings.vibrationEnabled;
      _aiMoveFirst = settings.aiMoveFirst;
    });

    // 应用音效设置
    await SoundManager().setVolume(_volume);
    SoundManager().setMuted(_volume == 0);
    await SoundManager().setBgmVolume(_bgmVolume);
    await SoundManager().setBgmEnabled(_bgmVolume > 0);
    // 震动
    SoundManager().setVibrationEnabled(_vibrationEnabled);

    debugPrint('✅ 设置已从本地加载:');
    debugPrint('  AI启用: $_aiEnabled');
    debugPrint('  AI难度: $_aiDifficulty');
    debugPrint('  音效启用: $_soundEnabled');
    debugPrint('  音量: $_volume');
    debugPrint('  背景音乐启用: $_bgmEnabled');
    debugPrint('  背景音乐音量: $_bgmVolume');
  }

  // 调试开关由 `AppConfig` 管理
  // (在开发环境默认开启, 发布环境默认关闭)
  // 通过修改 `lib/config/app_config.dart` 中的值进行控制

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // 使用纯色背景，移除背景图
      child: Scaffold(
        backgroundColor: Colors.white, // Scaffold 使用纯色背景
        appBar: AppBar(
          title: const Text('中国象棋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          centerTitle: true, // 标题居中
          backgroundColor: Colors.white, // AppBar 使用纯色背景
          foregroundColor: Colors.black,
          elevation: 0, // 移除阴影
          actions: [
            // 局面评估按钮 - 使用条件控制
            if (AppConfig.showDebugButtons)
              IconButton(
                icon: const Icon(Icons.analytics),
                onPressed: _showPositionEvaluation,
                tooltip: '局面评估',
              ),
            // AI 设置按钮 - 使用条件控制
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showAISettings,
            ), // 红方 AI 切换按钮 - 仅在开发环境显示（位于顶部设置旁）
            if (ApiConfig.isDevelopment)
              IconButton(
                icon: Icon(
                  Icons.computer,
                  color: _gameController?.redAIEnabled ?? false
                      ? Colors.red
                      : null,
                ),
                onPressed: () {
                  if (_gameController == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('游戏未就绪')),
                    );
                    return;
                  }
                  setState(() {
                    _gameController!.toggleRedAI();
                    _gameController!.setRedAIDifficulty(_hintDifficulty);
                  });
                  final enabled = _gameController!.redAIEnabled;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(enabled
                            ? '红方 AI 已启用 (难度: $_hintDifficulty)'
                            : '红方 AI 已禁用')),
                  );
                },
                tooltip: '红AI',
              ),
            // mTLS API 测试按钮 - 使用条件控制
            if (AppConfig.showDebugButtons)
              IconButton(
                icon: const Icon(Icons.cloud),
                onPressed: _navigateToMtlsTestPage,
                tooltip: 'API 测试',
              ),
            // 意见反馈按钮已移到设置页面
          ],
        ),
        body: SafeArea(
          child: Container(
            // Container背景透明,让外层的beijing.jpeg显示
            color: Colors.transparent,
            padding: const EdgeInsets.only(
                left: 8, top: 8, right: 8, bottom: 4), // 底部添加4的间距
            child: Column(
              children: [
                // 游戏棋盘 - 使用 Expanded 自动填充可用空间
                Expanded(
                  child: GameBoard(
                    aiEnabled: _aiEnabled,
                    aiDifficulty: _aiDifficulty,
                    onGameControllerReady: (controller) {
                      debugPrint('🎮 [主界面] GameController 已就绪');
                      // 使用 addPostFrameCallback 避免在 build 期间调用 setState
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _gameController = controller;
                        });
                        debugPrint(
                            '🎮 [主界面] _gameController 已设置: ${_gameController != null}');
                      });
                    },
                    onGameReset: () {
                      // 游戏重置后的回调
                      setState(() {});
                    },
                    onGameUndo: () {
                      // 撤销后的回调
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 6), // 固定间距
                // 底部状态栏
                Builder(
                  builder: (context) {
                    debugPrint(
                        '🔄 [主界面] 构建 BottomActionBar, _gameController: ${_gameController != null ? "已设置" : "NULL"}');
                    return BottomActionBar(
                      showDebugButtons: AppConfig.showDebugButtons,
                      aiEnabled: _aiEnabled,
                      hintDifficulty: _hintDifficulty,
                      gameController: _gameController,
                      onNewGame: _showNewGameDialog,
                      onUndo: _undoMove,
                      onGameInfo: _showGameInfo,
                      onEngineInfo: _showEngineInfo,
                    );
                  },
                ),
                const SizedBox(height: 4), // 固定间距
                // =====================================
                // |         **集成广告组件** |
                // =====================================
                _buildAdWithErrorBoundary(),
                // =====================================
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建带错误边界的广告组件
  Widget _buildAdWithErrorBoundary() {
    // 广告组件已在开源版中移除，始终返回空占位
    return const SizedBox.shrink();
  }

  /// 显示设置对话框
  void _showAISettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SettingsDialog(
          aiEnabled: _aiEnabled,
          aiDifficulty: _aiDifficulty,
          hintDifficulty: _hintDifficulty,
          soundEnabled: _soundEnabled,
          volume: _volume,
          aiMoveFirst: _aiMoveFirst,
          vibrationEnabled: _vibrationEnabled,
          onConfirm: (aiEnabled, aiDifficulty, hintDifficulty, soundEnabled,
              volume, vibrationEnabled, aiMoveFirst) async {
            setState(() {
              _aiEnabled = aiEnabled;
              _aiDifficulty = aiDifficulty;
              _hintDifficulty = hintDifficulty;
              _soundEnabled = soundEnabled;
              _volume = volume;
              _aiMoveFirst = aiMoveFirst;
              _vibrationEnabled = vibrationEnabled;
            });

            // 保存设置到本地
            await _saveSettings();

            // 应用设置
            _updateAISettings();
            // 如果启用了 AI 先行,并且 AI 开启,则尝试触发黑方开局走子
            if (_aiEnabled && _aiMoveFirst) {
              Future.microtask(() async => await _applyAIFirstMoveIfNeeded());
            }
          },
        );
      },
    );
  }

  /// 保存设置到本地存储
  Future<void> _saveSettings() async {
    final settings = AppSettings();
    await settings.saveAllSettings(
      aiEnabled: _aiEnabled,
      aiDifficulty: _aiDifficulty,
      hintDifficulty: _hintDifficulty,
      soundEnabled: _volume > 0,
      volume: _volume,
      bgmEnabled: _bgmVolume > 0,
      bgmVolume: _bgmVolume,
      vibrationEnabled: _vibrationEnabled,
      aiMoveFirst: _aiMoveFirst,
    );

    debugPrint('✅ 设置已保存到本地');
  }

  /// 显示游戏信息对话框
  void _showGameInfo() async {
    if (_gameController == null) return;
    final stats = _gameController!.getGameStats();
    final currentPlayer = _gameController!.isRedTurn ? '红方' : '黑方';
    final moveCount = _gameController!.moveHistory.length;
    final canUndo = _gameController!.fenHistory.length > 1;
    await showGameInfoDialog(
      context,
      currentPlayer: currentPlayer,
      moveCount: moveCount,
      canUndo: canUndo,
      stats: stats,
      aiEnabled: _aiEnabled,
      aiDifficulty: _aiDifficulty,
    );
  }

  /// 显示引擎信息对话框
  void _showEngineInfo() {
    EngineInfoDialog.show(context);
  }

  /// 导航到 mTLS 测试页面
  void _navigateToMtlsTestPage() {
    // mTLS 页面已移除/禁用以保护敏感配置信息
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已移除'),
        content: const Text('mTLS 功能已在开源版本中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 意见反馈的导航方法已移至设置对话框

  /// 显示新游戏确认对话框
  void _showNewGameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新游戏'),
          content: const Text('确定要开始新游戏吗？当前进度将会丢失。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 重置游戏
  void _resetGame() {
    _gameController?.resetGame();
    SnackBarHelper.showMessage(context, '游戏已重置');

    // 如果启用了 AI 先行，在新游戏后触发黑方首步
    if (_aiEnabled && _aiMoveFirst) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        await _applyAIFirstMoveIfNeeded();
      });
    }
  }

  /// 撤销上一步移动
  Future<void> _undoMove() async {
    if (_gameController == null) {
      SnackBarHelper.showMessage(context, '游戏未就绪');
      return;
    }

    final success = await _gameController!.undoLastMove();
    if (!mounted) return;
    if (success) {
      SnackBarHelper.showMessage(context, '已悔棋');
    } else {
      SnackBarHelper.showMessage(context, '无法悔棋，没有更多历史记录');
    }
  }

  /// 更新AI设置
  void _updateAISettings() {
    if (_gameController != null) {
      _gameController!.setAIDifficultyLevel(_aiDifficulty);
      _gameController!.setAIEnabled(_aiEnabled);
    }
    // 更新音效设置: 把音量为 0 视为静音
    SoundManager().setMuted(_volume == 0);
    // 更新音量设置
    SoundManager().setVolume(_volume);
    // 更新背景音乐设置: 把 bgmVolume 为 0 视为关闭
    SoundManager().setBgmEnabled(_bgmVolume > 0);
    SoundManager().setBgmVolume(_bgmVolume);
    // 震动设置
    SoundManager().setVibrationEnabled(_vibrationEnabled);
  }

  /// 显示局面评估对话框
  void _showPositionEvaluation() async {
    if (_gameController == null) {
      SnackBarHelper.showMessage(context, '游戏未就绪');
      return;
    }

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('正在评估'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在分析当前局面...'),
            ],
          ),
        );
      },
    );

    try {
      // 调用评估接口
      final evaluation = await _gameController!.evaluatePosition();

      if (!mounted) return;
      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示评估结果
      EvaluationResultDialog.show(context, evaluation, _gameController!);
    } catch (e) {
      if (!mounted) return;
      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示错误信息
      SnackBarHelper.show(
        context,
        SnackBar(
          content: Text('评估失败: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 如果满足条件，尝试让黑方AI使用开局库走第一步
  Future<void> _applyAIFirstMoveIfNeeded() async {
    try {
      if (_gameController == null) return;
      // 仅在棋局刚开始时应用（避免打断已进行的对局）
      if (_gameController!.moveHistory.isNotEmpty) return;
      // 只有在 AI 启用 且 设置了 AI 先行时执行
      if (!_aiEnabled || !_aiMoveFirst) return;

      // 加载黑方（forRed=false）的首步候选
      final candidates = await loadStartFirstMovesForSide(false);
      if (candidates.isEmpty) return;

      // 按 count 加权随机选择 (使用复用的 Random)
      final total = candidates.fold<int>(0, (s, e) => s + e.count);
      if (total <= 0) return;
      final r = _rand.nextInt(total);
      debugPrint('📚 开局首步候选总权重: $total, 随机值: $r');
      int acc = 0;
      FirstMoveEntry? chosen;
      for (var e in candidates) {
        acc += e.count;
        if (r < acc) {
          chosen = e;
          debugPrint('📌 选择首步: ${e.move} (count=${e.count}, 累积=$acc)');
          break;
        }
      }
      if (chosen == null) return;

      final uci = chosen.move;
      if (uci.length != 4) return;

      // 使用 GameController 提供的接口以黑方身份执行 UCI 走法
      final success = await _gameController!.playUciMove(uci, asBlack: true);
      if (!mounted) return;
      if (success) {
        SnackBarHelper.showMessage(context, '黑方AI已执行首步：$uci');
      }
    } catch (e, st) {
      debugPrint('⚠️ 应用AI首步失败: $e');
      debugPrint('$st');
    }
  }
}
