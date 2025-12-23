import 'package:flutter/material.dart';

/// 显示引擎信息对话框
class EngineInfoDialog extends StatelessWidget {
  const EngineInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('引擎信息'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('引擎: Pikafish'),
          SizedBox(height: 8),
          Text('版本: 最新版'),
          SizedBox(height: 8),
          Text('协议: UCI'),
          SizedBox(height: 8),
          Text('类型: 中国象棋引擎'),
          SizedBox(height: 8),
          Text('特性: 支持多线程、哈希表、技能等级调节'),
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

  /// 静态方法：显示引擎信息对话框
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return const EngineInfoDialog();
      },
    );
  }
}
