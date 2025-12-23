import 'package:flutter/material.dart';
import '../models/chess_piece.dart';

/// 移动验证器类 - 负责验证象棋所有棋子的移动规则
/// 包含帅/将、士、相/象、马、车、炮、兵/卒的移动规则验证
class MoveValidator {
  /// 获取棋盘上指定位置的棋子回调函数
  final ChessPiece? Function(int x, int y) getPieceAt;

  MoveValidator({required this.getPieceAt});

  /// 验证帅/将的移动规则
  bool isValidKingMove(
      ChessPiece king, int fromX, int fromY, int toX, int toY) {
    // 帅/将只能在九宫格内移动
    bool isRed = king.color == PieceColor.red;
    int minY = isRed ? 7 : 0;
    int maxY = isRed ? 9 : 2;

    if (toX < 3 || toX > 5 || toY < minY || toY > maxY) {
      debugPrint('帅/将移动失败: 超出九宫格范围');
      return false;
    }

    // 只能移动一格,且只能横向或纵向移动
    int deltaX = (toX - fromX).abs();
    int deltaY = (toY - fromY).abs();

    if ((deltaX == 1 && deltaY == 0) || (deltaX == 0 && deltaY == 1)) {
      return true;
    }

    debugPrint('帅/将移动失败: 只能移动一格');
    return false;
  }

  /// 验证士的移动规则
  bool isValidAdvisorMove(
      ChessPiece advisor, int fromX, int fromY, int toX, int toY) {
    // 士只能在九宫格内斜向移动
    bool isRed = advisor.color == PieceColor.red;
    int minY = isRed ? 7 : 0;
    int maxY = isRed ? 9 : 2;

    if (toX < 3 || toX > 5 || toY < minY || toY > maxY) {
      debugPrint('士移动失败: 超出九宫格范围');
      return false;
    }

    // 只能斜向移动一格
    int deltaX = (toX - fromX).abs();
    int deltaY = (toY - fromY).abs();

    if (deltaX == 1 && deltaY == 1) {
      return true;
    }

    debugPrint('士移动失败: 只能斜向移动一格');
    return false;
  }

  /// 验证相/象的移动规则
  bool isValidElephantMove(
      ChessPiece elephant, int fromX, int fromY, int toX, int toY) {
    // 相/象不能过河
    bool isRed = elephant.color == PieceColor.red;
    if (isRed && toY < 5) {
      debugPrint('相移动失败: 不能过河');
      return false;
    }
    if (!isRed && toY > 4) {
      debugPrint('象移动失败: 不能过河');
      return false;
    }

    // 斜向移动两格
    int deltaX = toX - fromX;
    int deltaY = toY - fromY;

    if (deltaX.abs() == 2 && deltaY.abs() == 2) {
      // 检查塞象眼
      int eyeX = fromX + deltaX ~/ 2;
      int eyeY = fromY + deltaY ~/ 2;

      if (getPieceAt(eyeX, eyeY) != null) {
        debugPrint('相/象移动失败: 塞象眼');
        return false;
      }
      return true;
    }

    debugPrint('相/象移动失败: 只能斜向移动两格');
    return false;
  }

  /// 验证马的移动规则
  bool isValidHorseMove(
      ChessPiece horse, int fromX, int fromY, int toX, int toY) {
    int deltaX = (toX - fromX).abs();
    int deltaY = (toY - fromY).abs();

    // 马走日字
    if (!((deltaX == 2 && deltaY == 1) || (deltaX == 1 && deltaY == 2))) {
      debugPrint('马移动失败: 不是日字形移动');
      return false;
    }

    // 检查蹩马腿
    int legX, legY;
    if (deltaX == 2) {
      legX = fromX + (toX - fromX) ~/ 2;
      legY = fromY;
    } else {
      legX = fromX;
      legY = fromY + (toY - fromY) ~/ 2;
    }

    if (getPieceAt(legX, legY) != null) {
      debugPrint('马移动失败: 蹩马腿');
      return false;
    }

    return true;
  }

  /// 验证车的移动规则
  bool isValidRookMove(
      ChessPiece rook, int fromX, int fromY, int toX, int toY) {
    // 车只能直线移动
    if (fromX != toX && fromY != toY) {
      debugPrint('车移动失败: 只能直线移动');
      return false;
    }

    // 检查路径上是否有棋子阻挡
    return isPathClear(fromX, fromY, toX, toY);
  }

  /// 验证炮的移动规则
  bool isValidCannonMove(ChessPiece cannon, int fromX, int fromY, int toX,
      int toY, ChessPiece? targetPiece) {
    // 炮只能直线移动
    if (fromX != toX && fromY != toY) {
      debugPrint('炮移动失败: 只能直线移动');
      return false;
    }

    // 统计路径上的棋子数量
    int pieceCount = countPiecesInPath(fromX, fromY, toX, toY);

    if (targetPiece == null) {
      // 不吃子时,路径必须畅通
      if (pieceCount == 0) {
        return true;
      } else {
        debugPrint('炮移动失败: 不吃子时路径不畅通,路径上有 $pieceCount 个棋子');
        return false;
      }
    } else {
      // 吃子时,路径上必须有且仅有一个棋子作为炮架
      if (pieceCount == 1) {
        return true;
      } else {
        debugPrint('炮吃子失败: 路径上必须有且仅有一个炮架,实际有 $pieceCount 个棋子');
        return false;
      }
    }
  }

  /// 验证兵/卒的移动规则
  bool isValidPawnMove(
      ChessPiece pawn, int fromX, int fromY, int toX, int toY) {
    bool isRed = pawn.color == PieceColor.red;
    int deltaX = (toX - fromX).abs();
    int deltaY = toY - fromY;

    // 兵/卒只能向前或横向移动一格
    if (deltaX > 1 || deltaY.abs() > 1 || (deltaX == 1 && deltaY != 0)) {
      debugPrint('兵/卒移动失败: 只能移动一格');
      return false;
    }

    // 未过河时只能向前
    if (isRed) {
      // 红兵
      if (fromY > 4) {
        // 未过河,只能向前
        if (deltaY != -1 || deltaX != 0) {
          debugPrint('红兵移动失败: 未过河只能向前');
          return false;
        }
      } else {
        // 已过河,可以向前或横向
        if (deltaY > 0 ||
            (deltaY == 0 && deltaX != 1) ||
            (deltaY < 0 && deltaY != -1)) {
          debugPrint('红兵移动失败: 过河后只能向前或横向移动');
          return false;
        }
      }
    } else {
      // 黑卒
      if (fromY < 5) {
        // 未过河,只能向前
        if (deltaY != 1 || deltaX != 0) {
          debugPrint('黑卒移动失败: 未过河只能向前');
          return false;
        }
      } else {
        // 已过河,可以向前或横向
        if (deltaY < 0 ||
            (deltaY == 0 && deltaX != 1) ||
            (deltaY > 0 && deltaY != 1)) {
          debugPrint('黑卒移动失败: 过河后只能向前或横向移动');
          return false;
        }
      }
    }

    return true;
  }

  /// 检查路径是否畅通(不包括起点和终点)
  bool isPathClear(int fromX, int fromY, int toX, int toY) {
    int pieceCount = countPiecesInPath(fromX, fromY, toX, toY);

    if (pieceCount > 0) {
      debugPrint('路径不畅通: 路径上有 $pieceCount 个棋子');
      return false;
    }

    return true;
  }

  /// 计算路径上的棋子数量(不包括起点和终点)
  int countPiecesInPath(int fromX, int fromY, int toX, int toY) {
    int count = 0;

    if (fromX == toX) {
      // 垂直移动
      int startY = fromY < toY ? fromY + 1 : toY + 1;
      int endY = fromY < toY ? toY : fromY;

      for (int y = startY; y < endY; y++) {
        if (getPieceAt(fromX, y) != null) {
          count++;
        }
      }
    } else if (fromY == toY) {
      // 水平移动
      int startX = fromX < toX ? fromX + 1 : toX + 1;
      int endX = fromX < toX ? toX : fromX;

      for (int x = startX; x < endX; x++) {
        if (getPieceAt(x, fromY) != null) {
          count++;
        }
      }
    }

    return count;
  }
}
