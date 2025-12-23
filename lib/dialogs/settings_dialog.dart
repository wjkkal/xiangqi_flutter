import 'package:flutter/material.dart';
import '../utils/sound_manager.dart';
import '../pages/feedback_page.dart';
import '../config/app_config.dart';

/// 游戏设置对话框
///
/// 提供AI开关、音效开关和AI难度调节功能
class SettingsDialog extends StatefulWidget {
  /// 当前AI是否启用
  final bool aiEnabled;

  /// 当前AI难度等级 (1-10)
  final int aiDifficulty;

  /// 当前音效是否启用
  final bool soundEnabled;

  /// 当前音效音量 (0.0-1.0)
  final double volume;

  /// 当前震动是否启用
  final bool vibrationEnabled;

  /// 是否让 AI 先行（黑方先走）
  final bool aiMoveFirst;

  /// 提示难度设置 (1-10)
  final int hintDifficulty;

  /// 确定按钮回调，返回新的设置值
  /// 参数顺序: aiEnabled, aiDifficulty, hintDifficulty, soundEnabled,
  /// volume, vibrationEnabled, aiMoveFirst
  final void Function(
      bool aiEnabled,
      int aiDifficulty,
      int hintDifficulty,
      bool soundEnabled,
      double volume,
      bool vibrationEnabled,
      bool aiMoveFirst) onConfirm;

  const SettingsDialog({
    super.key,
    required this.aiEnabled,
    required this.aiDifficulty,
    required this.soundEnabled,
    required this.volume,
    required this.hintDifficulty,
    required this.vibrationEnabled,
    required this.aiMoveFirst,
    required this.onConfirm,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _aiEnabled;
  late int _aiDifficulty;
  late bool _soundEnabled;
  late double _volume;
  late bool _vibrationEnabled;
  late int _hintDifficulty;
  late bool _aiMoveFirst;

  // 主题颜色定义
  static const Color _dialogBackgroundColor = Color(0xFFF5E6D3); // 浅米色/羊皮纸色
  static const Color _primaryTextColor = Color(0xFF3E2723); // 深褐色
  static const Color _secondaryTextColor = Color(0xFF5D4037); // 褐色
  static const Color _accentColor = Color(0xFF795548); // 棕色
  static const Color _dividerColor = Color(0xFFD7CCC8); // 浅棕色分割线

  @override
  void initState() {
    super.initState();
    _aiEnabled = widget.aiEnabled;
    _aiDifficulty = widget.aiDifficulty;
    _soundEnabled = widget.soundEnabled;
    _volume = widget.volume;
    _vibrationEnabled = widget.vibrationEnabled;
    _hintDifficulty = widget.hintDifficulty;
    _aiMoveFirst = widget.aiMoveFirst;
  }

  // AI 调试开关由 `AppConfig` 管理
  static const bool _showAIDebugButtons = AppConfig.showAIDebugButtons;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _dialogBackgroundColor,
      surfaceTintColor: Colors.transparent, // 移除 Material 3 的表面色调
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _accentColor, width: 2), // 添加边框
      ),
      title: Center(
        child: Column(
          children: [
            const Text(
              '设置',
              style: TextStyle(
                color: _primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 60,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 仅在调试模式显示 AI 设置
            if (_showAIDebugButtons) ...[
              _buildSectionHeader('对战设置'),
              _buildSwitchItem(
                context,
                icon: Icons.smart_toy,
                title: '启用AI对战',
                subtitle: 'AI将控制黑方',
                value: _aiEnabled,
                onChanged: (value) => setState(() => _aiEnabled = value),
              ),
              _buildDivider(),
              // AI 先行开关
              _buildSwitchItem(
                context,
                icon: Icons.skip_next,
                title: 'AI先行',
                subtitle: '黑方先走',
                value: _aiMoveFirst,
                onChanged: (value) => setState(() => _aiMoveFirst = value),
              ),
              if (_aiEnabled) ...[
                _buildDivider(),
                _buildSliderItem(
                  context,
                  icon: Icons.speed,
                  title: 'AI难度',
                  value: _aiDifficulty.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _aiDifficulty.toString(),
                  description: _getDifficultyDescription(_aiDifficulty),
                  descriptionColor: _getDifficultyColor(_aiDifficulty),
                  onChanged: (value) =>
                      setState(() => _aiDifficulty = value.round()),
                ),
              ],
              const SizedBox(height: 16),
            ],

            _buildSectionHeader('声音与提示'),
            // 音效音量
            _buildVolumeItem(
              context,
              icon: Icons.volume_up,
              title: '音效',
              value: _volume,
              onChanged: (value) async {
                setState(() => _volume = value);
                await SoundManager().setVolume(_volume);
              },
              onChangeEnd: (_) => _applyVolumeChange(),
            ),
            _buildDivider(),

            // 提示难度
            _buildSliderItem(
              context,
              icon: Icons.lightbulb_outline,
              title: '提示难度',
              value: _hintDifficulty.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _hintDifficulty.toString(),
              onChanged: (value) =>
                  setState(() => _hintDifficulty = value.round()),
            ),
            _buildDivider(),

            // 震动开关
            _buildSwitchItem(
              context,
              icon: Icons.vibration,
              title: '震动反馈',
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() => _vibrationEnabled = value);
                SoundManager().setVibrationEnabled(_vibrationEnabled);
              },
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('其他'),
            // 意见反馈
            _buildNavItem(
              context,
              icon: Icons.feedback_outlined,
              title: '意见反馈',
              subtitle: '提交问题或建议',
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                Future.microtask(() {
                  if (!mounted) return;
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryTextColor,
                  side: const BorderSide(color: _accentColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_aiEnabled, _aiDifficulty, _hintDifficulty,
                      _soundEnabled, _volume, _vibrationEnabled, _aiMoveFirst);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 60,
      endIndent: 24,
      color: _dividerColor,
    );
  }

  /// 播放测试音效,让用户立即听到音量大小
  void _applyVolumeChange() async {
    // 设置音量并根据是否为 0 决定静音
    await SoundManager().setVolume(_volume);
    SoundManager().setMuted(_volume == 0.0);
    // 若音量大于0，播放测试音效作为反馈
    if (_volume > 0) {
      await SoundManager().playMove();
    }
  }

  /// 获取难度描述
  String _getDifficultyDescription(int difficulty) {
    if (difficulty <= 2) {
      return '入门 - 适合新手学习';
    } else if (difficulty <= 4) {
      return '简单 - 轻松愉快';
    } else if (difficulty <= 6) {
      return '中等 - 需要思考';
    } else if (difficulty <= 8) {
      return '困难 - 颇具挑战';
    } else {
      return '专家 - 大师级别';
    }
  }

  /// 获取难度颜色
  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 2) {
      return Colors.green[700]!;
    } else if (difficulty <= 4) {
      return Colors.blue[700]!;
    } else if (difficulty <= 6) {
      return Colors.orange[800]!;
    } else if (difficulty <= 8) {
      return Colors.red[700]!;
    } else {
      return Colors.purple[700]!;
    }
  }

  /// 构建开关列表项
  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: _accentColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _secondaryTextColor
                              .withAlpha((0.8 * 255).round()),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: _accentColor,
                inactiveThumbColor: _accentColor,
                inactiveTrackColor: _accentColor.withAlpha((0.2 * 255).round()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建滑块列表项
  Widget _buildSliderItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    String? label,
    String? description,
    Color? descriptionColor,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: _accentColor),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: _primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${value.round()}',
                  style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _accentColor,
                    inactiveTrackColor:
                        _accentColor.withAlpha((0.2 * 255).round()),
                    thumbColor: _accentColor,
                    overlayColor: _accentColor.withAlpha((0.1 * 255).round()),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: label,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Text(
                description,
                style: TextStyle(
                  color: descriptionColor ?? _secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建音量控制列表项
  Widget _buildVolumeItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: _accentColor),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: _primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                value == 0 ? '已关闭' : '${(value * 100).round()}%',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentColor,
              inactiveTrackColor: _accentColor.withAlpha((0.2 * 255).round()),
              thumbColor: _accentColor,
              overlayColor: _accentColor.withAlpha((0.1 * 255).round()),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导航列表项
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: _accentColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _secondaryTextColor
                              .withAlpha((0.8 * 255).round()),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: _secondaryTextColor.withAlpha((0.5 * 255).round())),
            ],
          ),
        ),
      ),
    );
  }
}
