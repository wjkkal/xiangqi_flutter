import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// 中国象棋棋盘绘制器
class ChessBoardPainter extends CustomPainter {
  final double boardWidth;
  final double boardHeight;
  final ui.Image? boardImage; // 棋盘背景图片

  ChessBoardPainter({
    required this.boardWidth,
    required this.boardHeight,
    this.boardImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 为棋子预留边距，确保边缘棋子不被裁剪
    final double pieceMargin =
        (boardWidth + boardHeight) * 0.028; // 调整边距确保棋子完整显示

    // 计算实际棋盘绘制区域
    final double actualBoardWidth = boardWidth - 2 * pieceMargin;
    final double actualBoardHeight = boardHeight - 2 * pieceMargin;

    // 计算棋盘格子尺寸
    final double cellWidth = actualBoardWidth / 8; // 8个格子宽度
    final double cellHeight = actualBoardHeight / 9; // 9个格子高度

    // 绘制棋盘图片(包含完整的线条和背景)
    if (boardImage != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, boardWidth, boardHeight),
        image: boardImage!,
        fit: BoxFit.fill,
      );
    }

    // 平移画布以绘制在预留边距内
    canvas.translate(pieceMargin, pieceMargin);

    // 绘制楚河汉界文字
    _drawRiverText(canvas, cellWidth, cellHeight);
  }

  /// 绘制楚河汉界文字
  void _drawRiverText(Canvas canvas, double cellWidth, double cellHeight) {
    final double riverCenterY = 4.5 * cellHeight;

    // 绘制"楚河"文字
    _drawText(
      canvas,
      '楚河',
      Offset(2 * cellWidth, riverCenterY),
      fontSize: 24,
    );

    // 绘制"汉界"文字
    _drawText(
      canvas,
      '汉界',
      Offset(5.5 * cellWidth, riverCenterY),
      fontSize: 24,
    );
  }

  /// 绘制文字
  void _drawText(Canvas canvas, String text, Offset position,
      {double fontSize = 16}) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF5D4037), // 深褐色文字与线条统一
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 居中绘制文字
    final Offset drawPosition = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, drawPosition);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
