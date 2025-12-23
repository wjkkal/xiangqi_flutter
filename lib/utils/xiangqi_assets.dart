// 中国象棋图片资源管理类
class XiangqiAssets {
  // 棋盘背景
  static const String boardBackground = 'assets/images/board_background.png';

  // 红方棋子
  static const String redKing = 'assets/images/red_king.png'; // 帅
  static const String redAdvisor = 'assets/images/red_advisor.png'; // 仕
  static const String redElephant = 'assets/images/red_elephant.png'; // 相
  static const String redHorse = 'assets/images/red_horse.png'; // 马
  static const String redChariot = 'assets/images/red_chariot.png'; // 车
  static const String redCannon = 'assets/images/red_cannon.png'; // 炮
  static const String redSoldier = 'assets/images/red_soldier.png'; // 兵

  // 黑方棋子
  static const String blackKing = 'assets/images/black_king.png'; // 将
  static const String blackAdvisor = 'assets/images/black_advisor.png'; // 士
  static const String blackElephant = 'assets/images/black_elephant.png'; // 象
  static const String blackHorse = 'assets/images/black_horse.png'; // 马
  static const String blackChariot = 'assets/images/black_chariot.png'; // 车
  static const String blackCannon = 'assets/images/black_cannon.png'; // 炮
  static const String blackSoldier = 'assets/images/black_soldier.png'; // 卒

  // UI元素
  static const String selectedPiece = 'assets/images/selected_piece.png';
  static const String validMove = 'assets/images/valid_move.png';
  static const String lastMove = 'assets/images/last_move.png';

  // 列表：所有棋子资源（用于一次性预缓存）
  static const List<String> allPieceAssets = [
    redKing,
    redAdvisor,
    redElephant,
    redHorse,
    redChariot,
    redCannon,
    redSoldier,
    blackKing,
    blackAdvisor,
    blackElephant,
    blackHorse,
    blackChariot,
    blackCannon,
    blackSoldier,
  ];

  // 根据棋子类型获取对应的图片资源路径
  static String getPieceAsset(int piece) {
    switch (piece) {
      case 1:
        return redChariot; // 红车
      case 2:
        return redHorse; // 红马
      case 3:
        return redElephant; // 红相
      case 4:
        return redAdvisor; // 红仕
      case 5:
        return redKing; // 红帅
      case 6:
        return redCannon; // 红炮
      case 7:
        return redSoldier; // 红兵
      case 8:
        return blackChariot; // 黑车
      case 9:
        return blackHorse; // 黑马
      case 10:
        return blackElephant; // 黑象
      case 11:
        return blackAdvisor; // 黑士
      case 12:
        return blackKing; // 黑将
      case 13:
        return blackCannon; // 黑炮
      case 14:
        return blackSoldier; // 黑卒
      default:
        return '';
    }
  }
}
