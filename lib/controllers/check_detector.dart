import 'package:flutter/material.dart';
import '../models/chess_piece.dart';

/// 简单的2D点坐标类
class _Point {
  final int x;
  final int y;
  const _Point(this.x, this.y);
}

/// 将军检测器类 - 负责检测当前将/帅是否处于被将军状态
/// 包含所有将军检测相关的逻辑:车、炮、马、兵/卒、白脸将
class CheckDetector {
  /// 获取棋盘上指定位置的棋子回调函数
  final ChessPiece? Function(int x, int y) getPieceAt;

  /// 获取所有棋子列表回调函数
  final List<ChessPiece> Function() getPieces;

  CheckDetector({required this.getPieceAt, required this.getPieces});

  /// 检查指定颜色的将/帅是否被将军
  bool isInCheck(PieceColor kingColor) {
    try {
      final king = getPieces().firstWhere(
        (p) => p.type == PieceType.king && p.color == kingColor,
      );

      final opponentColor =
          kingColor == PieceColor.red ? PieceColor.black : PieceColor.red;

      // 1. 检查四个方向的车攻击
      if (isAttackedByRook(king, opponentColor)) {
        debugPrint('⚠️ 被车将军!');
        return true;
      }

      // 2. 检查四个方向的炮攻击
      if (isAttackedByCannon(king, opponentColor)) {
        debugPrint('⚠️ 被炮将军!');
        return true;
      }

      // 3. 检查马的8个日字位
      if (isAttackedByHorse(king, opponentColor)) {
        debugPrint('⚠️ 被马将军!');
        return true;
      }

      // 4. 检查兵/卒攻击
      if (isAttackedByPawn(king, opponentColor)) {
        debugPrint('⚠️ 被兵/卒将军!');
        return true;
      }

      // 5. 检查白脸将(对方将/帅直接面对面)
      if (isAttackedByKing(king, opponentColor)) {
        debugPrint('⚠️ 白脸将!');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('检查将军状态失败: $e');
      return false;
    }
  }

  /// 检查是否被车攻击
  bool isAttackedByRook(ChessPiece king, PieceColor opponentColor) {
    final directions = [
      const _Point(0, -1),
      const _Point(0, 1), // 上下
      const _Point(-1, 0),
      const _Point(1, 0), // 左右
    ];

    for (final dir in directions) {
      int nx = king.x + dir.x;
      int ny = king.y + dir.y;

      while (nx >= 0 && nx <= 8 && ny >= 0 && ny <= 9) {
        final piece = getPieceAt(nx, ny);
        if (piece != null) {
          if (piece.color == opponentColor && piece.type == PieceType.rook) {
            return true;
          }
          break; // 遇到任何棋子就停止
        }
        nx += dir.x;
        ny += dir.y;
      }
    }
    return false;
  }

  /// 检查是否被炮攻击
  bool isAttackedByCannon(ChessPiece king, PieceColor opponentColor) {
    final directions = [
      const _Point(0, -1),
      const _Point(0, 1),
      const _Point(-1, 0),
      const _Point(1, 0),
    ];

    for (final dir in directions) {
      int nx = king.x + dir.x;
      int ny = king.y + dir.y;
      bool foundScreen = false; // 是否找到炮架

      while (nx >= 0 && nx <= 8 && ny >= 0 && ny <= 9) {
        final piece = getPieceAt(nx, ny);
        if (piece != null) {
          if (!foundScreen) {
            foundScreen = true; // 第一个棋子作为炮架
          } else {
            // 第二个棋子检查是否是对方炮
            if (piece.color == opponentColor &&
                piece.type == PieceType.cannon) {
              return true;
            }
            break;
          }
        }
        nx += dir.x;
        ny += dir.y;
      }
    }
    return false;
  }

  /// 检查是否被马攻击
  bool isAttackedByHorse(ChessPiece king, PieceColor opponentColor) {
    // 马的8个可能攻击位置(日字)
    final horseOffsets = [
      [const _Point(-2, -1), const _Point(-1, 0)], // 左上
      [const _Point(-2, 1), const _Point(-1, 0)], // 左下
      [const _Point(2, -1), const _Point(1, 0)], // 右上
      [const _Point(2, 1), const _Point(1, 0)], // 右下
      [const _Point(-1, -2), const _Point(0, -1)], // 上左
      [const _Point(1, -2), const _Point(0, -1)], // 上右
      [const _Point(-1, 2), const _Point(0, 1)], // 下左
      [const _Point(1, 2), const _Point(0, 1)], // 下右
    ];

    for (final move in horseOffsets) {
      final target = move[0];
      final block = move[1];

      final nx = king.x + target.x;
      final ny = king.y + target.y;
      final bx = king.x + block.x;
      final by = king.y + block.y;

      if (nx >= 0 && nx <= 8 && ny >= 0 && ny <= 9) {
        // 检查是否有蹩马腿
        if (getPieceAt(bx, by) == null) {
          final piece = getPieceAt(nx, ny);
          if (piece?.color == opponentColor && piece?.type == PieceType.horse) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// 检查是否被兵/卒攻击
  bool isAttackedByPawn(ChessPiece king, PieceColor opponentColor) {
    // 兵/卒攻击位置(红兵向上,黑卒向下)
    final isKingRed = king.color == PieceColor.red;
    final pawnOffsets = isKingRed
        ? [
            const _Point(-1, 0),
            const _Point(1, 0),
            const _Point(0, -1)
          ] // 红帅被黑卒攻击(左右上)
        : [
            const _Point(-1, 0),
            const _Point(1, 0),
            const _Point(0, 1)
          ]; // 黑将被红兵攻击(左右下)

    for (final offset in pawnOffsets) {
      final nx = king.x + offset.x;
      final ny = king.y + offset.y;

      if (nx >= 0 && nx <= 8 && ny >= 0 && ny <= 9) {
        final piece = getPieceAt(nx, ny);
        if (piece?.color == opponentColor && piece?.type == PieceType.pawn) {
          return true;
        }
      }
    }
    return false;
  }

  /// 检查白脸将(对方将/帅直接照面)
  bool isAttackedByKing(ChessPiece king, PieceColor opponentColor) {
    // 检查将/帅所在列是否有对方将/帅,且中间无棋子
    int ny = king.y + (king.color == PieceColor.red ? -1 : 1);

    while (ny >= 0 && ny <= 9) {
      final piece = getPieceAt(king.x, ny);
      if (piece != null) {
        if (piece.color == opponentColor && piece.type == PieceType.king) {
          return true;
        }
        break;
      }
      ny += (king.color == PieceColor.red ? -1 : 1);
    }
    return false;
  }
}
