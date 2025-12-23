import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// 棋盘图片加载器
class BoardImageLoader {
  static ui.Image? _cachedImage;
  static bool _isLoading = false;

  /// 加载棋盘背景图片
  static Future<ui.Image?> loadBoardImage() async {
    // 如果已经缓存,直接返回
    if (_cachedImage != null) {
      return _cachedImage;
    }

    // 如果正在加载,等待加载完成
    if (_isLoading) {
      // 等待一段时间后重试
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedImage;
    }

    _isLoading = true;

    try {
      // 从 assets 加载图片
      final ByteData data =
          await rootBundle.load('assets/images/board_background.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frameInfo = await codec.getNextFrame();
      _cachedImage = frameInfo.image;
      debugPrint('✅ 棋盘背景图片加载成功');
      return _cachedImage;
    } catch (e) {
      debugPrint('⚠️ 棋盘背景图片加载失败: $e');
      return null;
    } finally {
      _isLoading = false;
    }
  }

  /// 清除缓存
  static void clearCache() {
    _cachedImage?.dispose();
    _cachedImage = null;
  }
}
