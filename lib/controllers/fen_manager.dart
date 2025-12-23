import '../models/chess_piece.dart';

/// FEN字符串管理器
/// 负责FEN字符串的解析和生成
class FenManager {
  /// 从FEN字符串更新棋子列表
  ///
  /// 如果传入 [previousPieces]，会尽可能地重用已有棋子的 `id`（按类型/颜色优先匹配相同位置，
  /// 否则按最近距离匹配），以便在 UI 层使用 `AnimatedPositioned` 时保持元素稳定，避免全部重建导致不必要的动画。
  static List<ChessPiece> parseFenToPieces(String fenString,
      {List<ChessPiece>? previousPieces}) {
    final fenPosition = fenString.split(' ')[0];
    return _parseFenPosition(fenPosition, previousPieces: previousPieces);
  }

  /// 从棋子列表生成FEN字符串
  static String generateFenFromPieces(
    List<ChessPiece> pieces,
    bool isRedTurn,
    int moveCount,
  ) {
    final StringBuffer fenBoard = StringBuffer();

    for (int y = 0; y < 10; y++) {
      int emptyCount = 0;

      for (int x = 0; x < 9; x++) {
        final ChessPiece? piece = _getPieceAt(pieces, x, y);

        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            fenBoard.write(emptyCount);
            emptyCount = 0;
          }
          fenBoard.write(_pieceToFenChar(piece));
        }
      }

      if (emptyCount > 0) {
        fenBoard.write(emptyCount);
      }

      if (y < 9) {
        fenBoard.write('/');
      }
    }

    final String turn = isRedTurn ? 'w' : 'b';
    return '${fenBoard.toString()} $turn - - 0 ${moveCount ~/ 2 + 1}';
  }

  /// 解析FEN位置字符串
  static List<ChessPiece> _parseFenPosition(String fenPosition,
      {List<ChessPiece>? previousPieces}) {
    final List<ChessPiece> parsedPieces = [];
    final rows = fenPosition.split('/');

    // 可复用的上一轮棋子副本（用于分配稳定 id）
    final List<ChessPiece> availPrev =
        previousPieces != null ? List<ChessPiece>.from(previousPieces) : [];

    // 跟踪已使用的 id，确保不会分配重复 id（修复悔棋后吃子导致的 Duplicate keys 问题）
    final Set<int> usedIds = {};
    // 为避免分配冲突，准备一个增长 id 源，初始值为现有 id 的最大值 + 1
    int nextGeneratedId = 0;
    if (availPrev.isNotEmpty) {
      nextGeneratedId =
          availPrev.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    for (int y = 0; y < rows.length && y < 10; y++) {
      int x = 0;
      for (int i = 0; i < rows[y].length; i++) {
        final char = rows[y][i];

        if (char.contains(RegExp(r'[1-9]'))) {
          x += int.parse(char);
        } else {
          // 解析出类型与颜色后，尝试在可用的上一轮棋子中匹配以复用 id
          final isRed = char.toUpperCase() == char;
          final color = isRed ? PieceColor.red : PieceColor.black;

          PieceType? type;
          switch (char.toLowerCase()) {
            case 'k':
              type = PieceType.king;
              break;
            case 'a':
              type = PieceType.advisor;
              break;
            case 'b':
              type = PieceType.elephant;
              break;
            case 'n':
              type = PieceType.horse;
              break;
            case 'r':
              type = PieceType.rook;
              break;
            case 'c':
              type = PieceType.cannon;
              break;
            case 'p':
              type = PieceType.pawn;
              break;
          }

          int? matchedId;

          if (type != null && availPrev.isNotEmpty) {
            // 优先按相同位置匹配
            final posIndex = availPrev.indexWhere((p) =>
                p.type == type && p.color == color && p.x == x && p.y == y);

            if (posIndex != -1) {
              matchedId = availPrev[posIndex].id;
              usedIds.add(matchedId);
              availPrev.removeAt(posIndex);
            } else {
              // 按类型/颜色并选择最短曼哈顿距离的未匹配棋子
              int bestIdx = -1;
              int bestDist = 1 << 30;
              for (int k = 0; k < availPrev.length; k++) {
                final p = availPrev[k];
                if (p.type == type && p.color == color) {
                  final dist = (p.x - x).abs() + (p.y - y).abs();
                  if (dist < bestDist) {
                    bestDist = dist;
                    bestIdx = k;
                  }
                }
              }

              if (bestIdx != -1) {
                matchedId = availPrev[bestIdx].id;
                usedIds.add(matchedId);
                availPrev.removeAt(bestIdx);
              }
            }
          }

          // 若未找到匹配 id，则确保分配一个全局唯一的 id，避免与未匹配的旧 id 冲突
          int assignedId;
          if (matchedId != null) {
            assignedId = matchedId;
          } else {
            // 首选使用 parsedPieces.length 以保持向后兼容，但若已被占用则使用 nextGeneratedId
            assignedId = parsedPieces.length;
            if (usedIds.contains(assignedId) ||
                availPrev.any((p) => p.id == assignedId)) {
              assignedId = nextGeneratedId++;
            }
          }

          usedIds.add(assignedId);

          final piece = ChessPiece.fromFenChar(char, x, y, id: assignedId);
          if (piece != null) {
            parsedPieces.add(piece);
          }
          x++;
        }

        if (x >= 9) break;
      }
    }

    return parsedPieces;
  }

  /// 将棋子转换为FEN字符
  static String _pieceToFenChar(ChessPiece piece) {
    String char;
    switch (piece.type) {
      case PieceType.king:
        char = 'k';
        break;
      case PieceType.advisor:
        char = 'a';
        break;
      case PieceType.elephant:
        char = 'b';
        break;
      case PieceType.horse:
        char = 'n';
        break;
      case PieceType.rook:
        char = 'r';
        break;
      case PieceType.cannon:
        char = 'c';
        break;
      case PieceType.pawn:
        char = 'p';
        break;
    }

    return piece.color == PieceColor.red ? char.toUpperCase() : char;
  }

  /// 从棋子列表中获取指定位置的棋子
  static ChessPiece? _getPieceAt(List<ChessPiece> pieces, int x, int y) {
    try {
      return pieces.firstWhere((piece) => piece.x == x && piece.y == y);
    } catch (e) {
      return null;
    }
  }

  /// 从FEN字符串中提取当前回合
  static bool isRedTurnFromFen(String fenString) {
    final parts = fenString.split(' ');
    if (parts.length >= 2) {
      return parts[1] == 'w';
    }
    return true; // 默认红方先行
  }

  /// 生成移动记录符号(UCI格式)
  static String generateMoveNotation(int fromX, int fromY, int toX, int toY) {
    final String from = '${String.fromCharCode(97 + fromX)}${9 - fromY}';
    final String to = '${String.fromCharCode(97 + toX)}${9 - toY}';
    return '$from$to';
  }

  /// 生成带吃子标记的移动记录
  static String generateMoveNotationWithCapture(
      int fromX, int fromY, int toX, int toY, bool isCapture) {
    final String from = '${String.fromCharCode(97 + fromX)}${9 - fromY}';
    final String to = '${String.fromCharCode(97 + toX)}${9 - toY}';
    final String capture = isCapture ? 'x' : '-';
    return '$from$capture$to';
  }
}
