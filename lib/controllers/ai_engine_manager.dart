import 'dart:io';
import 'package:flutter/material.dart';
import '../generated/uci_api.dart';
import '../models/chess_piece.dart';

/// AI引擎管理器
/// 负责与Pikafish引擎交互,提供AI走法计算和走法验证
class AIEngineManager {
  /// UCI API 实例
  final UciApi _uciApi = UciApi();

  /// 引擎是否已初始化
  bool _engineInitialized = false;

  /// AI 难度等级 (1-10)
  int _aiDifficultyLevel = 5;

  /// 是否启用AI对战
  bool _aiEnabled = false;

  /// AI是否正在计算中
  bool _isAIThinking = false;

  /// 获取引擎初始化状态
  bool get isEngineInitialized => _engineInitialized;

  /// 获取AI难度等级
  int get aiDifficultyLevel => _aiDifficultyLevel;

  /// 获取AI启用状态
  bool get isAIEnabled => _aiEnabled;

  /// 获取AI是否正在计算中
  bool get isAIThinking => _isAIThinking;

  /// 初始化象棋引擎
  Future<void> initializeEngine() async {
    try {
      if (!_engineInitialized) {
        debugPrint('🔧 开始初始化象棋引擎...');
        final startTime = DateTime.now();

        await _uciApi.initializeEngine();

        // 计算线程数: CPU核心数除以2,最小为1
        final cpuCores = Platform.numberOfProcessors;
        final threads = (cpuCores / 2).floor().clamp(1, cpuCores);

        final config = EngineConfig(
          threads: threads,
          hashSize: 128,
          skillLevel: _aiDifficultyLevel,
          depth: 8,
          moveTime: 1000,
        );

        await _uciApi.configureEngine(config);
        _engineInitialized = true;

        final duration = DateTime.now().difference(startTime);
        debugPrint(
            '✅ 象棋引擎初始化成功 (耗时: ${duration.inMilliseconds}ms, CPU核心数: $cpuCores, 引擎线程数: $threads, 哈希表: 128MB)');
      }
    } catch (e) {
      debugPrint('❌ 象棋引擎初始化失败: $e');
    }
  }

  /// 启用或禁用AI对战
  Future<void> setAIEnabled(bool enabled) async {
    _aiEnabled = enabled;
    if (_aiEnabled && !_engineInitialized) {
      await initializeEngine();
    }
  }

  /// 设置AI难度等级
  void setAIDifficultyLevel(int level) {
    if (level >= 1 && level <= 10) {
      _aiDifficultyLevel = level;
    }
  }

  /// 获取AI推荐的最佳走法
  Future<String?> getAIBestMove(String currentFen) async {
    if (!_engineInitialized || !_aiEnabled) {
      return null;
    }

    // 检查是否正在计算中
    if (_isAIThinking) {
      debugPrint('⚠️  AI正在计算中，忽略重复请求');
      return null;
    }

    debugPrint('========== AI 走法计算开始 ==========');
    debugPrint('🎯 AI难度等级: $_aiDifficultyLevel');
    debugPrint('📋 当前局面: $currentFen');

    _isAIThinking = true; // 标记开始计算
    try {
      final stopwatch = Stopwatch()..start();

      await _uciApi.setPosition(currentFen);
      final bestMove =
          await _uciApi.getBestMove(currentFen, _aiDifficultyLevel);

      stopwatch.stop();
      debugPrint('✅ AI 选择走法: $bestMove');
      debugPrint('⏱️  计算耗时: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('========== AI 走法计算完成 ==========');

      return bestMove;
    } catch (e) {
      debugPrint('❌ 获取AI最佳走法失败: $e');
      debugPrint('========== AI 走法计算失败 ==========');
      return null;
    } finally {
      _isAIThinking = false; // 无论成功还是失败都要重置标志
    }
  }

  /// 使用引擎验证走法合法性
  Future<bool> validateMoveWithEngine(
      String currentFen, int fromX, int fromY, int toX, int toY) async {
    if (!_engineInitialized) {
      await initializeEngine();
      if (!_engineInitialized) {
        debugPrint('引擎未初始化，跳过引擎验证');
        return false;
      }
    }

    try {
      final fromFile = String.fromCharCode('a'.codeUnitAt(0) + fromX);
      final fromRank = 9 - fromY;
      final toFile = String.fromCharCode('a'.codeUnitAt(0) + toX);
      final toRank = 9 - toY;
      final uciMove = '$fromFile$fromRank$toFile$toRank';

      debugPrint('🔍 引擎验证走法: $uciMove (坐标: ($fromX,$fromY) -> ($toX,$toY))');

      await _uciApi.setPosition(currentFen);
      final validation = await _uciApi.isMoveLegal(currentFen, uciMove);

      if (validation.isLegal) {
        return true;
      } else {
        debugPrint('引擎判定走法不合法: ${validation.errorMessage ?? "未知原因"}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ 引擎验证出现异常: $e');
      return false;
    }
  }

  /// 检查游戏是否结束
  Future<GameEndResult> checkGameEnd(
      String currentFen, List<ChessPiece> pieces) async {
    // 首先检查将帅是否还在棋盘上
    bool hasRedKing = pieces.any((piece) =>
        piece.type == PieceType.king && piece.color == PieceColor.red);
    bool hasBlackKing = pieces.any((piece) =>
        piece.type == PieceType.king && piece.color == PieceColor.black);

    if (!hasRedKing) {
      debugPrint('🏁 游戏结束: 红方帅被吃掉，黑方胜利！');
      return GameEndResult(isEnd: true, isCheckmate: true, winner: 'black');
    }

    if (!hasBlackKing) {
      debugPrint('🏁 游戏结束: 黑方将被吃掉，红方胜利！');
      return GameEndResult(isEnd: true, isCheckmate: true, winner: 'red');
    }

    if (!_engineInitialized) {
      debugPrint('❌ 引擎未初始化，跳过游戏结束检查');
      return GameEndResult(isEnd: false);
    }

    try {
      final isCheckmate = await _uciApi.isCheckmate(currentFen);
      final isStalemate = await _uciApi.isStalemate(currentFen);

      if (isCheckmate) {
        debugPrint('🏁 游戏结束: 将死！');
        return GameEndResult(isEnd: true, isCheckmate: true);
      } else if (isStalemate) {
        debugPrint('🏁 游戏结束: 僵局/困毙');
        return GameEndResult(isEnd: true, isStalemate: true);
      }

      return GameEndResult(isEnd: false);
    } catch (e) {
      debugPrint('❌ 检查游戏结束状态失败: $e');
      return GameEndResult(isEnd: false);
    }
  }

  /// 评估当前局面
  Future<int> evaluatePosition(String currentFen) async {
    if (!_engineInitialized) {
      throw Exception('引擎未初始化');
    }

    try {
      return await _uciApi.evaluatePosition(currentFen);
    } catch (e) {
      debugPrint('评估局面失败: $e');
      throw Exception('评估局面失败: $e');
    }
  }

  /// 获取当前位置的详细分析
  Future<EngineAnalysis?> getPositionAnalysis(String currentFen,
      {int depth = 8, int timeLimit = 5000}) async {
    if (!_engineInitialized) {
      return null;
    }

    try {
      return await _uciApi.analyzePosition(currentFen, depth, timeLimit);
    } catch (e) {
      debugPrint('获取位置分析失败: $e');
      return null;
    }
  }

  /// 获取所有合法走法
  Future<List<String>> getLegalMoves(String currentFen) async {
    if (!_engineInitialized) {
      return [];
    }

    try {
      return await _uciApi.getLegalMoves(currentFen);
    } catch (e) {
      debugPrint('获取合法走法失败: $e');
      return [];
    }
  }

  /// 获取引擎信息
  Future<String> getEngineInfo() async {
    if (!_engineInitialized) {
      return '引擎未初始化';
    }

    try {
      return await _uciApi.getEngineInfo();
    } catch (e) {
      return '获取引擎信息失败: $e';
    }
  }

  /// 重置引擎
  Future<void> resetEngine() async {
    if (_engineInitialized) {
      try {
        await _uciApi.resetEngine();
      } catch (e) {
        debugPrint('重置引擎失败: $e');
      }
    }
  }

  /// 获取AI状态信息
  Map<String, dynamic> getAIStatus() {
    return {
      'enabled': _aiEnabled,
      'initialized': _engineInitialized,
      'difficultyLevel': _aiDifficultyLevel,
    };
  }
}

/// 游戏结束结果
class GameEndResult {
  final bool isEnd;
  final bool isCheckmate;
  final bool isStalemate;
  final String? winner;

  GameEndResult({
    required this.isEnd,
    this.isCheckmate = false,
    this.isStalemate = false,
    this.winner,
  });
}
