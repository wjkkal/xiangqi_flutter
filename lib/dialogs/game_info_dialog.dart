import 'package:flutter/material.dart';
import '../utils/device_info_helper.dart';

Future<void> showGameInfoDialog(
  BuildContext context, {
  required String currentPlayer,
  required int moveCount,
  required bool canUndo,
  required Map<String, dynamic> stats,
  required bool aiEnabled,
  required int aiDifficulty,
}) async {
  final deviceInfo = await getDeviceInfo();
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('游戏信息'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 游戏信息部分
              Text(
                '游戏状态',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const Divider(),
              Text('当前轮次: $currentPlayer'),
              const SizedBox(height: 6),
              Text('移动步数: $moveCount'),
              const SizedBox(height: 6),
              Text('可悔棋: ${canUndo ? "是" : "否"}'),
              const SizedBox(height: 6),
              Text('游戏状态: ${stats['gameState']}'),
              const SizedBox(height: 6),
              Text('棋子数量: ${stats['piecesCount']}'),
              if (aiEnabled) ...[
                const SizedBox(height: 6),
                Text('AI难度: $aiDifficulty/10'),
              ],
              // 设备信息部分
              const SizedBox(height: 16),
              Text(
                '设备信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const Divider(),
              Text('平台: ${deviceInfo.platform}'),
              const SizedBox(height: 6),
              Text('设备名称: ${deviceInfo.deviceName}'),
              const SizedBox(height: 6),
              Text('设备型号: ${deviceInfo.deviceModel}'),
              const SizedBox(height: 6),
              Text('系统版本: ${deviceInfo.osVersion}'),
              const SizedBox(height: 6),
              Text('国家代码: ${deviceInfo.countryCode}'),
              ...deviceInfo.additionalInfo.map((info) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(info),
                  )),
            ],
          ),
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
    },
  );
}
