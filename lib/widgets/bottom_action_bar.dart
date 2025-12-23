import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../utils/snackbar_helper.dart';
// api_config import removed; top-level AppBar now hosts Red-AI button

/// 底部操作栏组件
///
/// 显示游戏控制按钮,包括新游戏、悔棋、游戏信息和引擎信息等按钮
class BottomActionBar extends StatefulWidget {
  /// 是否显示调试按钮
  final bool showDebugButtons;

  /// 是否启用AI
  final bool aiEnabled;

  /// 提示难度（用于 AI 提示）
  final int hintDifficulty;

  /// 游戏控制器
  final GameController? gameController;

  /// 新游戏按钮点击回调
  final VoidCallback onNewGame;

  /// 悔棋按钮点击回调
  final VoidCallback onUndo;

  /// 游戏信息按钮点击回调
  final VoidCallback onGameInfo;

  /// 引擎信息按钮点击回调
  final VoidCallback onEngineInfo;

  const BottomActionBar({
    super.key,
    this.showDebugButtons = false,
    this.aiEnabled = true,
    this.hintDifficulty = 8,
    this.gameController,
    required this.onNewGame,
    required this.onUndo,
    required this.onGameInfo,
    required this.onEngineInfo,
  });

  @override
  State<BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<BottomActionBar> {
  @override
  void initState() {
    super.initState();
    _setupStateListener();
  }

  @override
  void didUpdateWidget(BottomActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 gameController 发生变化,重新设置监听
    if (oldWidget.gameController != widget.gameController) {
      _setupStateListener();
    }
  }

  void _setupStateListener() {
    // 监听游戏控制器状态变化
    widget.gameController?.setOnStateChanged(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      // 移除白色背景，让按钮图片直接显示在透明背景上
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 新游戏按钮 -> 使用文字按钮替代图片
          _buildCompactButton(
            onPressed: widget.onNewGame,
            label: '新游戏',
            tooltip: '新游戏',
            textColor: Colors.black87,
            backgroundColor: Colors.transparent,
          ),

          // 悔棋按钮 -> 使用文字按钮替代图片
          _buildCompactButton(
            onPressed: widget.onUndo,
            label: '悔棋',
            tooltip: '悔棋',
            textColor: Colors.black87,
            backgroundColor: Colors.transparent,
          ),

          // 提示按钮 -> 使用文字按钮替代图片
          _buildCompactButton(
            onPressed: () async {
              if (widget.gameController == null) {
                SnackBarHelper.showMessage(context, '游戏未就绪');
                return;
              }

              // 捕获 ScaffoldMessenger 以便在 await 之后也能安全显示 SnackBar
              final messenger = ScaffoldMessenger.of(context);
              messenger.removeCurrentSnackBar();
              messenger.showSnackBar(const SnackBar(
                  content: Text('AI 计算中，请稍候...'),
                  duration: Duration(seconds: 2)));

              try {
                final suggestion = await widget.gameController!
                    .getHintFromEngine(difficulty: widget.hintDifficulty);

                if (!mounted) return;

                // 检查是否AI正在计算中
                if (suggestion == 'AI_THINKING') {
                  messenger.removeCurrentSnackBar();
                  messenger.showSnackBar(const SnackBar(
                      content: Text('AI 正在思考中，请稍候...'),
                      duration: Duration(seconds: 2)));
                  return;
                }

                if (suggestion == null || suggestion.isEmpty) {
                  messenger.removeCurrentSnackBar();
                  messenger
                      .showSnackBar(const SnackBar(content: Text('AI 未能给出建议')));
                } else {
                  // 成功获取建议 — 在棋盘上高亮显示（不直接显示 UCI 字符串）
                  messenger.removeCurrentSnackBar();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('AI 建议已在棋盘上高亮显示')));
                }
              } catch (e) {
                if (!mounted) return;
                messenger.removeCurrentSnackBar();
                messenger.showSnackBar(SnackBar(content: Text('获取提示失败: $e')));
              }
            },
            label: '提示',
            tooltip: '提示',
            textColor: Colors.black87,
            backgroundColor: Colors.transparent,
          ),
          // 注: 红方 AI 按钮已移至顶部 AppBar（仅在开发环境显示）
          // 游戏信息按钮 - 使用条件控制
          if (widget.showDebugButtons)
            _buildCompactButton(
              onPressed: widget.onGameInfo,
              icon: Icons.info_outline,
              label: '信息',
            ),
          // 引擎信息按钮 - 使用条件控制
          if (widget.showDebugButtons && widget.aiEnabled)
            _buildCompactButton(
              onPressed: widget.onEngineInfo,
              icon: Icons.smart_toy,
              label: 'AI',
            ),
        ],
      ),
    );
  }

  // 创建紧凑型按钮
  Widget _buildCompactButton({
    required VoidCallback onPressed,
    IconData? icon,
    Widget? iconWidget,
    String? label,
    String? tooltip,
    Color? iconColor,
    Color? textColor,
    Color? backgroundColor,
  }) {
    // 选择合适的前景色，默认使用主题的 onBackground，以保证对比度
    final effectiveTextColor =
        textColor ?? Theme.of(context).colorScheme.onSurface;
    final effectiveIconColor = iconColor ?? Theme.of(context).iconTheme.color;

    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        backgroundColor: backgroundColor ?? Colors.transparent,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 支持图片或 Icon
          if (iconWidget != null)
            iconWidget
          else if (icon != null)
            Icon(icon, size: 18, color: effectiveIconColor)
          else
            const SizedBox.shrink(),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: effectiveTextColor)),
          ],
        ],
      ),
    );

    // 如果提供了 tooltip, 用 Tooltip 包裹按钮，方便无障碍和鼠标悬停说明
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: button);
    }

    return button;
  }
}
