import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';

/// 显示局面评估结果对话框
class EvaluationResultDialog extends StatelessWidget {
  final int evaluation;
  final GameController gameController;

  const EvaluationResultDialog({
    super.key,
    required this.evaluation,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    final String evaluationText = _formatEvaluation(evaluation);
    final String advantage = _getAdvantageDescription(evaluation);
    final Color advantageColor = _getAdvantageColor(evaluation);
    final IconData advantageIcon = _getAdvantageIcon(evaluation);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue),
          SizedBox(width: 8),
          Text('局面评估'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前轮次
          Text(
            '当前轮次: ${gameController.isRedTurn ? "红方" : "黑方"}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // 评估分数
          Row(
            children: [
              const Text('评估分数: ', style: TextStyle(fontSize: 16)),
              Text(
                evaluationText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: advantageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 优势描述
          Row(
            children: [
              Icon(advantageIcon, color: advantageColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  advantage,
                  style: TextStyle(
                    fontSize: 16,
                    color: advantageColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 说明文字
          const Text(
            '注: 正数表示红方占优，负数表示黑方占优。分数越大优势越明显。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  /// 格式化评估分数
  String _formatEvaluation(int evaluation) {
    if (evaluation == 0) {
      return '0 (平衡)';
    } else if (evaluation > 0) {
      return '+$evaluation';
    } else {
      return evaluation.toString();
    }
  }

  /// 获取优势描述
  String _getAdvantageDescription(int evaluation) {
    final absEval = evaluation.abs();

    if (evaluation == 0) {
      return '局面平衡';
    } else if (absEval <= 50) {
      return '${evaluation > 0 ? "红方" : "黑方"}轻微优势';
    } else if (absEval <= 150) {
      return '${evaluation > 0 ? "红方" : "黑方"}明显优势';
    } else if (absEval <= 300) {
      return '${evaluation > 0 ? "红方" : "黑方"}很大优势';
    } else {
      return '${evaluation > 0 ? "红方" : "黑方"}压倒性优势';
    }
  }

  /// 获取优势颜色
  Color _getAdvantageColor(int evaluation) {
    if (evaluation == 0) {
      return Colors.grey;
    } else if (evaluation > 0) {
      return Colors.red; // 红方优势用红色
    } else {
      return Colors.black87; // 黑方优势用黑色
    }
  }

  /// 获取优势图标
  IconData _getAdvantageIcon(int evaluation) {
    final absEval = evaluation.abs();

    if (evaluation == 0) {
      return Icons.balance;
    } else if (absEval <= 50) {
      return Icons.trending_up;
    } else if (absEval <= 150) {
      return Icons.arrow_upward;
    } else {
      return Icons.keyboard_double_arrow_up;
    }
  }

  /// 静态方法：显示评估对话框
  static Future<void> show(
    BuildContext context,
    int evaluation,
    GameController gameController,
  ) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return EvaluationResultDialog(
          evaluation: evaluation,
          gameController: gameController,
        );
      },
    );
  }
}
