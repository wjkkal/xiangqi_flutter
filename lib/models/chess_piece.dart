import 'dart:math';

/// 中国象棋棋子类型枚举
enum PieceType {
  king, // 帅/将
  advisor, // 仕/士
  elephant, // 相/象
  horse, // 马
  rook, // 车
  cannon, // 炮
  pawn, // 兵/卒
}

/// 棋子颜色枚举
enum PieceColor {
  red, // 红方
  black, // 黑方
}

/// 中国象棋棋子数据类
class ChessPiece {
  final PieceType type;
  final PieceColor color;
  final int x; // 列坐标 (0-8)
  final int y; // 行坐标 (0-9)
  final int id; // 唯一标识符，与位置无关

  ChessPiece({
    required this.type,
    required this.color,
    required this.x,
    required this.y,
    int? id,
  }) : id = id ?? Random().nextInt(1000000); // 生成随机id

  /// 从FEN字符获取棋子类型和颜色
  static ChessPiece? fromFenChar(String fenChar, int x, int y, {int? id}) {
    if (fenChar == ' ' || fenChar == '/' || fenChar.isEmpty) {
      return null;
    }

    final isRed = fenChar.toUpperCase() == fenChar;
    final color = isRed ? PieceColor.red : PieceColor.black;

    PieceType? type;
    switch (fenChar.toLowerCase()) {
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
      default:
        return null;
    }

    return ChessPiece(
      type: type,
      color: color,
      x: x,
      y: y,
      id: id,
    );
  }

  /// 获取棋子的中文名称
  String get chineseName {
    switch (type) {
      case PieceType.king:
        return color == PieceColor.red ? '帅' : '将';
      case PieceType.advisor:
        return color == PieceColor.red ? '仕' : '士';
      case PieceType.elephant:
        return color == PieceColor.red ? '相' : '象';
      case PieceType.horse:
        return color == PieceColor.red ? '马' : '马';
      case PieceType.rook:
        return color == PieceColor.red ? '车' : '车';
      case PieceType.cannon:
        return color == PieceColor.red ? '炮' : '炮';
      case PieceType.pawn:
        return color == PieceColor.red ? '兵' : '卒';
    }
  }

  /// 获取对应的图片资源路径
  String get assetPath {
    final colorPrefix = color == PieceColor.red ? 'red' : 'black';
    switch (type) {
      case PieceType.king:
        return 'assets/images/${colorPrefix}_king.png';
      case PieceType.advisor:
        return 'assets/images/${colorPrefix}_advisor.png';
      case PieceType.elephant:
        return 'assets/images/${colorPrefix}_elephant.png';
      case PieceType.horse:
        return 'assets/images/${colorPrefix}_horse.png';
      case PieceType.rook:
        // 文件使用中文习惯命名为 chariot
        return 'assets/images/${colorPrefix}_chariot.png';
      case PieceType.cannon:
        return 'assets/images/${colorPrefix}_cannon.png';
      case PieceType.pawn:
        // 兵/卒 资源文件命名为 soldier
        return 'assets/images/${colorPrefix}_soldier.png';
    }
  }

  /// 复制棋子并更新位置
  ChessPiece copyWith({int? x, int? y}) {
    return ChessPiece(
      type: type,
      color: color,
      x: x ?? this.x,
      y: y ?? this.y,
      id: id, // 保持相同的id
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChessPiece &&
        other.type == type &&
        other.color == color &&
        other.x == x &&
        other.y == y &&
        other.id == id;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        color.hashCode ^
        x.hashCode ^
        y.hashCode ^
        id.hashCode;
  }

  @override
  String toString() {
    return 'ChessPiece(type: $type, color: $color, x: $x, y: $y, id: $id)';
  }
}
