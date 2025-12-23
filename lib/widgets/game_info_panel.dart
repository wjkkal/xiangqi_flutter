import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../config/app_config.dart';

/// 游戏信息面板 - 楚河汉界·对弈战板风格
class GameInfoPanel extends StatelessWidget {
  // 读取 AppConfig 中的 AI 调试开关
  static const bool _showAIDebugButtons = AppConfig.showAIDebugButtons;
  final GameController gameController;
  final bool? aiEnabled;
  final int? aiDifficulty;

  // 颜色定义
  static const Color _redColor = Color(0xFFB71C1C); // 朱红
  static const Color _blackColor = Color(0xFF212121); // 墨黑
  static const Color _highlightColor = Color(0xFFFFD700); // 金黄

  const GameInfoPanel({
    super.key,
    required this.gameController,
    this.aiEnabled,
    this.aiDifficulty,
  });

  /// 格式化时间显示（秒 -> MM:SS）
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRedTurn = gameController.isRedTurn;
    final redTotalTime = gameController.redTotalTimeSeconds;
    final blackTotalTime = gameController.blackTotalTimeSeconds;

    return Container(
      height: 80, // 固定高度，确保布局稳定
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.brown[50], // 使用纯色背景替代图片
        borderRadius: BorderRadius.circular(12),
        // 深褐色边框，增加立体感
        // border: Border.all(color: const Color(0xFF5D4037), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：红方阵地
          Expanded(
            child: _buildPlayerSection(
              isRed: true,
              isActive: isRedTurn,
              timeSeconds: redTotalTime,
            ),
          ),

          // 中间：战局状态
          _buildCenterStatus(isRedTurn),

          // 右侧：黑方阵地
          Expanded(
            child: _buildPlayerSection(
              isRed: false,
              isActive: !isRedTurn,
              timeSeconds: blackTotalTime,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建玩家区域 (红方/黑方)
  Widget _buildPlayerSection({
    required bool isRed,
    required bool isActive,
    required int timeSeconds,
  }) {
    final color = isRed ? _redColor : _blackColor;
    final label = isRed ? '帅' : '将';

    return Container(
      decoration: BoxDecoration(
        // 高亮当前回合背景
        gradient: isActive
            ? LinearGradient(
                begin: isRed ? Alignment.centerLeft : Alignment.centerRight,
                end: isRed ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  color.withAlpha((0.15 * 255).round()),
                  Colors.transparent,
                ],
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment:
            isRed ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isRed) const SizedBox(width: 4), // 减少边缘间距

          // 棋子图标与时间信息的排列
          if (isRed) ...[
            _buildChessPieceIcon(label, color, isActive),
            const SizedBox(width: 4), // 减少内部间距
            Expanded(
                child: _buildTimeDisplay(
                    timeSeconds, color, isActive)), // 使用Expanded避免溢出
          ] else ...[
            Expanded(
                child: _buildTimeDisplay(
                    timeSeconds, color, isActive)), // 使用Expanded避免溢出
            const SizedBox(width: 4), // 减少内部间距
            _buildChessPieceIcon(label, color, isActive),
          ],

          if (!isRed) const SizedBox(width: 4), // 减少边缘间距
        ],
      ),
    );
  }

  /// 构建拟物化棋子图标
  Widget _buildChessPieceIcon(String label, Color color, bool isActive) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE6CBA8), // 棋子底色 (木色)
        border: Border.all(
          color: isActive ? _highlightColor : const Color(0xFF8D6E63),
          width: isActive ? 3 : 2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: _highlightColor.withAlpha((0.6 * 255).round()),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).round()),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: color.withAlpha((0.3 * 255).round()), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'KaiTi', // 尝试使用楷体，如果没有则回退
            height: 1.0,
          ),
        ),
      ),
    );
  }

  /// 构建时间显示
  Widget _buildTimeDisplay(int seconds, Color color, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          // 自动缩放以适应宽度
          fit: BoxFit.scaleDown,
          child: Text(
            _formatTime(seconds),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? color : color.withAlpha((0.6 * 255).round()),
              fontFamily: 'monospace',
              shadows: isActive
                  ? [
                      Shadow(
                        color: Colors.white.withAlpha((0.8 * 255).round()),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建中间状态栏
  Widget _buildCenterStatus(bool isRedTurn) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主标题：谁走棋
          Text(
            isRedTurn ? '红方走棋' : '黑方走棋',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isRedTurn ? _redColor : _blackColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          // 副标签：AI/难度 (卷轴样式)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), // 浅黄纸色
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA1887F)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (aiEnabled == true) ...[
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 12,
                    color: Colors.brown[800],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showAIDebugButtons ? 'Lv.${aiDifficulty ?? 5}' : 'AI对弈',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.brown[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else
                  Text(
                    '双人对战',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.brown[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
