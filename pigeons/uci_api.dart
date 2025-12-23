import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/uci_api.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/app/src/main/kotlin/com/example/xiangqi_flutter/UciApi.kt',
  kotlinOptions: KotlinOptions(package: 'com.example.xiangqi_flutter'),
  swiftOut: 'ios/Runner/UciApi.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'xiangqi_flutter',
))

/// 引擎状态枚举
enum EngineState {
  /// 未初始化
  uninitialized,

  /// 正在初始化
  initializing,

  /// 已就绪
  ready,

  /// 正在思考
  thinking,

  /// 出错
  error,
}

/// 引擎配置选项
class EngineConfig {
  EngineConfig({
    required this.threads,
    required this.hashSize,
    required this.skillLevel,
    required this.depth,
    required this.moveTime,
  });

  /// 引擎使用的线程数
  final int threads;

  /// 哈希表大小(MB)
  final int hashSize;

  /// 技能等级 (0-20, 20最强)
  final int skillLevel;

  /// 搜索深度
  final int depth;

  /// 思考时间(毫秒)
  final int moveTime;
}

/// 引擎分析结果
class EngineAnalysis {
  EngineAnalysis({
    required this.bestMove,
    required this.ponderMove,
    required this.score,
    required this.depth,
    required this.nodes,
    required this.nps,
    required this.time,
    required this.pv,
  });

  /// 最佳走法 (UCI格式，如 "e2e4")
  final String bestMove;

  /// 预测对手走法
  final String? ponderMove;

  /// 评分 (厘兵为单位，正数表示当前方占优)
  final int score;

  /// 搜索深度
  final int depth;

  /// 搜索节点数
  final int nodes;

  /// 每秒搜索节点数
  final int nps;

  /// 思考时间(毫秒)
  final int time;

  /// 主要变例 (最佳走法序列)
  final List<String> pv;
}

/// 走法验证结果
class MoveValidation {
  MoveValidation({
    required this.isLegal,
    required this.errorMessage,
  });

  /// 走法是否合法
  final bool isLegal;

  /// 错误信息 (如果走法不合法)
  final String? errorMessage;
}

/// Pikafish象棋引擎的UCI接口
/// 用于与C++引擎进行通信
@HostApi()
abstract class UciApi {
  /// 初始化象棋引擎
  /// 必须在使用其他方法之前调用
  @async
  void initializeEngine();

  /// 配置引擎参数
  /// @param config 引擎配置选项
  @async
  void configureEngine(EngineConfig config);

  /// 获取引擎当前状态
  EngineState getEngineState();

  /// 设置当前棋局位置
  /// @param fen FEN格式的棋局字符串
  @async
  void setPosition(String fen);

  /// 根据当前位置获取最佳走法
  /// @param fen FEN格式的棋局字符串
  /// @param difficultyLevel 难度等级 (1-10, 10最难)
  /// @return 引擎计算的最佳走法 (UCI格式，如 "e2e4")
  @async
  String getBestMove(String fen, int difficultyLevel);

  /// 获取详细的引擎分析结果
  /// @param fen FEN格式的棋局字符串
  /// @param depth 搜索深度
  /// @param timeLimit 时间限制(毫秒)
  /// @return 详细的分析结果
  @async
  EngineAnalysis analyzePosition(String fen, int depth, int timeLimit);

  /// 验证走法是否合法
  /// @param fen 当前局面的FEN字符串
  /// @param move UCI格式的走法 (如 "e2e4")
  /// @return 走法验证结果
  @async
  MoveValidation isMoveLegal(String fen, String move);

  /// 执行走法并返回新的FEN
  /// @param fen 当前局面的FEN字符串
  /// @param move UCI格式的走法
  /// @return 执行走法后的新FEN字符串
  @async
  String makeMove(String fen, String move);

  /// 撤销最后一步走法
  /// @return 撤销后的FEN字符串
  @async
  String undoMove();

  /// 获取当前局面的所有合法走法
  /// @param fen FEN格式的棋局字符串
  /// @return 所有合法走法的列表 (UCI格式)
  @async
  List<String> getLegalMoves(String fen);

  /// 评估当前局面
  /// @param fen FEN格式的棋局字符串
  /// @return 局面评分 (厘兵为单位)
  @async
  int evaluatePosition(String fen);

  /// 检查是否将军
  /// @param fen FEN格式的棋局字符串
  /// @return 是否处于将军状态
  bool isInCheck(String fen);

  /// 检查是否将死
  /// @param fen FEN格式的棋局字符串
  /// @return 是否将死
  bool isCheckmate(String fen);

  /// 检查是否和棋/平局
  /// @param fen FEN格式的棋局字符串
  /// @return 是否和棋
  bool isStalemate(String fen);

  /// 停止引擎思考
  void stopEngine();

  /// 重置引擎到初始状态
  @async
  void resetEngine();

  /// 获取引擎信息
  /// @return 引擎名称和版本信息
  String getEngineInfo();

  /// 释放引擎资源
  @async
  void dispose();
}
