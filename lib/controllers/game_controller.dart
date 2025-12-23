import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chess_piece.dart';
import '../generated/uci_api.dart';
import '../utils/sound_manager.dart';
import 'ai_engine_manager.dart';
import 'fen_manager.dart';
import 'move_validator.dart';
import 'check_detector.dart';

/// 游戏状态枚举
enum GameState {
  playing, // 正在游戏
  checkmate, // 将死
  stalemate, // 和棋
  draw, // 平局
}

/// 走法验证结果
class MoveValidationResult {
  final bool isValid;
  final String reason;

  const MoveValidationResult(this.isValid, this.reason);
}

/// 通用验证结果
class ValidationResult {
  final bool isValid;
  final String reason;

  const ValidationResult(this.isValid, this.reason);
}

/// 游戏控制器，管理整个象棋游戏的状态和逻辑
class GameController {
  /// AI引擎管理器
  final AIEngineManager _aiEngine = AIEngineManager();

  /// 音效管理器
  final SoundManager _soundManager = SoundManager();

  /// 移动验证器
  late final MoveValidator _moveValidator;

  /// 将军检测器
  late final CheckDetector _checkDetector;

  /// 游戏状态变化回调列表（支持多个监听器）
  final List<VoidCallback> _stateChangedListeners = [];

  /// 最近一个需要 UI 通知的事件 (例如 'check')
  String? _lastNotification;

  /// 当前棋盘的FEN表示
  String _currentFen;

  /// 当前轮到的玩家 (true: 红方, false: 黑方)
  bool _isRedTurn;

  /// 红方 AI 是否启用（仅开发模式使用）
  bool _redAIEnabled = false;

  /// 红方 AI 难度（与提示难度一致）
  int _redAIDifficulty = 8;

  /// 游戏状态
  GameState _gameState;

  /// 移动历史记录
  final List<String> _moveHistory = [];

  /// FEN 历史记录栈，用于悔棋功能
  final List<String> _fenHistory = [];

  /// 当前棋子列表（从FEN解析而来）
  List<ChessPiece> _pieces = [];

  /// 游戏开始时间
  DateTime? _gameStartTime;

  /// 当前回合开始时间
  DateTime? _currentMoveStartTime;

  /// 红方总用时（毫秒）
  int _redTotalTime = 0;

  /// 黑方总用时（毫秒）
  int _blackTotalTime = 0;

  /// 当前回合用时（毫秒）
  int _currentMoveTime = 0;

  /// 最后一步移动的起始位置
  Point<int>? _lastMoveFrom;

  /// 最后一步移动的目标位置
  Point<int>? _lastMoveTo;

  /// AI 建议的起始位置（提示）
  Point<int>? _lastHintFrom;

  /// AI 建议的目标位置（提示）
  Point<int>? _lastHintTo;

  /// 构造函数，使用标准开局FEN初始化
  GameController({
    String? initialFen,
    bool isRedTurn = true,
    bool enableAI = false,
    int aiDifficultyLevel = 5,
  })  : _currentFen = initialFen ??
            "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1",
        _isRedTurn = isRedTurn,
        _gameState = GameState.playing {
    _updatePiecesFromFen();
    // 将初始状态加入历史记录
    _fenHistory.add(_currentFen);
    // 初始化计时器
    _gameStartTime = DateTime.now();
    _currentMoveStartTime = DateTime.now();
    // 初始化移动验证器和将军检测器
    _moveValidator = MoveValidator(getPieceAt: getPieceAt);
    _checkDetector = CheckDetector(
      getPieceAt: getPieceAt,
      getPieces: () => _pieces,
    );
    // 初始化AI引擎 - 延迟到后台异步加载,避免阻塞主线程
    if (enableAI) {
      _aiEngine.setAIDifficultyLevel(aiDifficultyLevel);
      // 异步初始化,不阻塞构造函数
      Future.microtask(() async {
        await _aiEngine.setAIEnabled(true);
        debugPrint('✅ AI引擎已在后台初始化完成');
      });
    }
  }

  /// 获取当前FEN字符串
  String get currentFen => _currentFen;

  /// 获取当前轮到的玩家
  bool get isRedTurn => _isRedTurn;

  /// 获取红方 AI 是否启用
  bool get redAIEnabled => _redAIEnabled;

  /// 获取游戏状态
  GameState get gameState => _gameState;

  /// 获取当前棋子列表
  List<ChessPiece> get pieces => List.unmodifiable(_pieces);

  /// 获取移动历史
  List<String> get moveHistory => List.unmodifiable(_moveHistory);

  /// 获取FEN历史记录
  List<String> get fenHistory => List.unmodifiable(_fenHistory);

  /// 获取最后一步移动的起始位置
  Point<int>? get lastMoveFrom => _lastMoveFrom;

  /// 获取最后一步移动的目标位置
  Point<int>? get lastMoveTo => _lastMoveTo;

  /// 获取 AI 提示的起始位置
  Point<int>? get lastHintFrom => _lastHintFrom;

  /// 获取 AI 提示的目标位置
  Point<int>? get lastHintTo => _lastHintTo;

  /// 获取指定棋子的所有可能移动位置（使用本地规则快速计算）
  /// 参数：x, y - 棋子的坐标
  /// 返回：该棋子的所有可能目标位置列表 [Point(x, y), ...]
  /// 注意：这里只做基本移动规则检查，不检查是否会导致己方被将军
  List<Point<int>> getLegalMovesForPiece(int x, int y) {
    final piece = getPieceAt(x, y);
    if (piece == null) return [];

    final moves = <Point<int>>[];

    switch (piece.type) {
      case PieceType.king: // 将/帅
        _addKingMoves(piece, moves);
        break;
      case PieceType.advisor: // 士
        _addAdvisorMoves(piece, moves);
        break;
      case PieceType.elephant: // 象
        _addElephantMoves(piece, moves);
        break;
      case PieceType.horse: // 马
        _addHorseMoves(piece, moves);
        break;
      case PieceType.rook: // 车
        _addChariotMoves(piece, moves);
        break;
      case PieceType.cannon: // 炮
        _addCannonMoves(piece, moves);
        break;
      case PieceType.pawn: // 兵/卒
        _addPawnMoves(piece, moves);
        break;
    }

    return moves;
  }

  /// 添加将/帅的可移动位置
  void _addKingMoves(ChessPiece king, List<Point<int>> moves) {
    final isRed = king.color == PieceColor.red;
    // 九宫格范围
    const minX = 3, maxX = 5;
    final minY = isRed ? 7 : 0;
    final maxY = isRed ? 9 : 2;

    // 上下左右四个方向
    final directions = [
      const Point(0, -1),
      const Point(0, 1),
      const Point(-1, 0),
      const Point(1, 0)
    ];

    for (final dir in directions) {
      final newX = king.x + dir.x;
      final newY = king.y + dir.y;

      if (newX >= minX && newX <= maxX && newY >= minY && newY <= maxY) {
        final target = getPieceAt(newX, newY);
        if (target == null || target.color != king.color) {
          moves.add(Point(newX, newY));
        }
      }
    }
  }

  /// 添加士的可移动位置
  void _addAdvisorMoves(ChessPiece advisor, List<Point<int>> moves) {
    final isRed = advisor.color == PieceColor.red;
    // 九宫格范围
    const minX = 3, maxX = 5;
    final minY = isRed ? 7 : 0;
    final maxY = isRed ? 9 : 2;

    // 四个斜向
    final directions = [
      const Point(-1, -1),
      const Point(-1, 1),
      const Point(1, -1),
      const Point(1, 1)
    ];

    for (final dir in directions) {
      final newX = advisor.x + dir.x;
      final newY = advisor.y + dir.y;

      if (newX >= minX && newX <= maxX && newY >= minY && newY <= maxY) {
        final target = getPieceAt(newX, newY);
        if (target == null || target.color != advisor.color) {
          moves.add(Point(newX, newY));
        }
      }
    }
  }

  /// 添加象的可移动位置
  void _addElephantMoves(ChessPiece elephant, List<Point<int>> moves) {
    final isRed = elephant.color == PieceColor.red;
    final riverBoundary = isRed ? 5 : 4; // 不能过河

    // 四个田字方向
    final moves2 = [
      const Point(-2, -2),
      const Point(-2, 2),
      const Point(2, -2),
      const Point(2, 2)
    ];
    final blocks = [
      const Point(-1, -1),
      const Point(-1, 1),
      const Point(1, -1),
      const Point(1, 1)
    ];

    for (int i = 0; i < moves2.length; i++) {
      final newX = elephant.x + moves2[i].x;
      final newY = elephant.y + moves2[i].y;
      final blockX = elephant.x + blocks[i].x;
      final blockY = elephant.y + blocks[i].y;

      // 检查是否过河
      if (isRed && newY < riverBoundary) continue;
      if (!isRed && newY > riverBoundary) continue;

      // 检查范围
      if (newX < 0 || newX > 8 || newY < 0 || newY > 9) continue;

      // 检查象眼是否被塞
      if (getPieceAt(blockX, blockY) != null) continue;

      // 检查目标位置
      final target = getPieceAt(newX, newY);
      if (target == null || target.color != elephant.color) {
        moves.add(Point(newX, newY));
      }
    }
  }

  /// 添加马的可移动位置
  void _addHorseMoves(ChessPiece horse, List<Point<int>> moves) {
    final horseMoves = [
      [const Point(0, -1), const Point(-1, -2)],
      [const Point(0, -1), const Point(1, -2)],
      [const Point(0, 1), const Point(-1, 2)],
      [const Point(0, 1), const Point(1, 2)],
      [const Point(-1, 0), const Point(-2, -1)],
      [const Point(-1, 0), const Point(-2, 1)],
      [const Point(1, 0), const Point(2, -1)],
      [const Point(1, 0), const Point(2, 1)],
    ];

    for (final move in horseMoves) {
      final blockX = horse.x + move[0].x;
      final blockY = horse.y + move[0].y;
      final newX = horse.x + move[1].x;
      final newY = horse.y + move[1].y;

      // 检查范围
      if (newX < 0 || newX > 8 || newY < 0 || newY > 9) continue;

      // 检查马脚是否被别
      if (getPieceAt(blockX, blockY) != null) continue;

      // 检查目标位置
      final target = getPieceAt(newX, newY);
      if (target == null || target.color != horse.color) {
        moves.add(Point(newX, newY));
      }
    }
  }

  /// 添加车的可移动位置
  void _addChariotMoves(ChessPiece chariot, List<Point<int>> moves) {
    // 四个方向：上下左右
    final directions = [
      const Point(0, -1),
      const Point(0, 1),
      const Point(-1, 0),
      const Point(1, 0)
    ];

    for (final dir in directions) {
      int newX = chariot.x + dir.x;
      int newY = chariot.y + dir.y;

      while (newX >= 0 && newX <= 8 && newY >= 0 && newY <= 9) {
        final target = getPieceAt(newX, newY);

        if (target == null) {
          moves.add(Point(newX, newY));
        } else {
          if (target.color != chariot.color) {
            moves.add(Point(newX, newY));
          }
          break; // 遇到棋子停止
        }

        newX += dir.x;
        newY += dir.y;
      }
    }
  }

  /// 添加炮的可移动位置
  void _addCannonMoves(ChessPiece cannon, List<Point<int>> moves) {
    // 四个方向：上下左右
    final directions = [
      const Point(0, -1),
      const Point(0, 1),
      const Point(-1, 0),
      const Point(1, 0)
    ];

    for (final dir in directions) {
      int newX = cannon.x + dir.x;
      int newY = cannon.y + dir.y;
      bool hasJumped = false;

      while (newX >= 0 && newX <= 8 && newY >= 0 && newY <= 9) {
        final target = getPieceAt(newX, newY);

        if (!hasJumped) {
          // 未翻山：可以移动到空位
          if (target == null) {
            moves.add(Point(newX, newY));
          } else {
            hasJumped = true; // 遇到棋子作为炮台
          }
        } else {
          // 已翻山：只能吃子
          if (target != null) {
            if (target.color != cannon.color) {
              moves.add(Point(newX, newY));
            }
            break; // 吃子后停止
          }
        }

        newX += dir.x;
        newY += dir.y;
      }
    }
  }

  /// 添加兵/卒的可移动位置
  void _addPawnMoves(ChessPiece pawn, List<Point<int>> moves) {
    final isRed = pawn.color == PieceColor.red;
    final hasRiver = isRed ? (pawn.y < 5) : (pawn.y > 4);

    // 前进方向
    final forwardDir = isRed ? -1 : 1;
    final newY = pawn.y + forwardDir;

    if (newY >= 0 && newY <= 9) {
      final target = getPieceAt(pawn.x, newY);
      if (target == null || target.color != pawn.color) {
        moves.add(Point(pawn.x, newY));
      }
    }

    // 过河后可以左右移动
    if (hasRiver) {
      for (final dx in [-1, 1]) {
        final newX = pawn.x + dx;
        if (newX >= 0 && newX <= 8) {
          final target = getPieceAt(newX, pawn.y);
          if (target == null || target.color != pawn.color) {
            moves.add(Point(newX, pawn.y));
          }
        }
      }
    }
  }

  /// 获取游戏总用时（秒）
  int get totalGameTimeSeconds {
    if (_gameStartTime == null) return 0;
    return DateTime.now().difference(_gameStartTime!).inSeconds;
  }

  /// 获取红方总用时（秒）
  int get redTotalTimeSeconds => (_redTotalTime / 1000).round();

  /// 获取黑方总用时（秒）
  int get blackTotalTimeSeconds => (_blackTotalTime / 1000).round();

  /// 获取当前回合用时（秒）
  int get currentMoveTimeSeconds {
    if (_currentMoveStartTime == null) return 0;
    final elapsed =
        DateTime.now().difference(_currentMoveStartTime!).inMilliseconds;
    return ((elapsed + _currentMoveTime) / 1000).round();
  }

  /// 设置状态变化回调
  void setOnStateChanged(VoidCallback? callback) {
    if (callback != null) {
      _stateChangedListeners.add(callback);
      debugPrint(
          '📌 [GameController] 添加监听器，总数: ${_stateChangedListeners.length}');
    }
  }

  /// 通知状态发生变化
  void _notifyStateChanged() {
    debugPrint(
        '📣 [GameController] _notifyStateChanged 被调用，gameState=$_gameState, 监听器数量=${_stateChangedListeners.length}');
    for (var listener in _stateChangedListeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('⚠️ [GameController] 监听器执行异常: $e');
      }
    }
  }

  /// 获取并清除最近的通知事件（UI消费后会被清空）
  String? consumeLastNotification() {
    final v = _lastNotification;
    _lastNotification = null;
    return v;
  }

  /// 移动棋子的主要方法
  /// 参数：fromX, fromY 起始位置；toX, toY 目标位置
  /// 返回：是否移动成功
  Future<bool> movePiece(int fromX, int fromY, int toX, int toY) async {
    debugPrint('');
    debugPrint('=== 开始移动验证 ===');
    debugPrint('📌 从坐标: ($fromX, $fromY) -> ($toX, $toY)');

    // 检查游戏是否已经结束
    if (_gameState != GameState.playing) {
      debugPrint('❌ 移动失败: 游戏已结束 (状态: $_gameState)');
      return false;
    }

    // 检查坐标有效性
    if (!_isValidCoordinate(fromX, fromY) || !_isValidCoordinate(toX, toY)) {
      debugPrint('❌ 移动失败: 坐标无效 ($fromX,$fromY) -> ($toX,$toY)');
      return false;
    }

    // 获取起始位置的棋子
    final ChessPiece? movingPiece = getPieceAt(fromX, fromY);
    if (movingPiece == null) {
      debugPrint('❌ 移动失败: 起始位置($fromX,$fromY)没有棋子');
      return false; // 起始位置没有棋子
    }

    debugPrint('📍 移动棋子: ${movingPiece.type} (${movingPiece.color})');

    // 检查是否是当前玩家的棋子
    if (!_isCurrentPlayerPiece(movingPiece)) {
      debugPrint('❌ 移动失败: 不是当前玩家的棋子 (当前回合: ${_isRedTurn ? "红方" : "黑方"})');
      return false; // 不是当前玩家的棋子
    }

    // 获取目标位置的棋子
    final ChessPiece? targetPiece = getPieceAt(toX, toY);

    // if (targetPiece != null) {
    //   debugPrint('📍 目标位置: ${targetPiece.type} (${targetPiece.color})');
    // } else {
    //   debugPrint('📍 目标位置: 空');
    // }

    // 检查是否试图吃己方棋子
    if (targetPiece != null && targetPiece.color == movingPiece.color) {
      debugPrint('❌ 移动失败: 不能吃己方棋子');
      return false; // 不能吃己方棋子
    }

    debugPrint('⏳ 开始引擎验证...');
    // 使用AI引擎验证移动是否符合象棋规则
    final isValidMove = await _validateMoveWithEngine(
        fromX, fromY, toX, toY, movingPiece, targetPiece);
    if (!isValidMove) {
      debugPrint('❌ 移动失败: AI引擎验证不通过');
      debugPrint('=== 移动验证结束 ===');
      debugPrint('');
      return false;
    }

    debugPrint('✅ 验证通过，执行移动');

    // 记录当前回合用时
    _recordMoveTime();

    // 执行移动
    _executMove(movingPiece, fromX, fromY, toX, toY, targetPiece);

    // 记录最后一步移动位置
    _lastMoveFrom = Point(fromX, fromY);
    _lastMoveTo = Point(toX, toY);

    // 执行任何移动后清除之前的 AI 提示
    _lastHintFrom = null;
    _lastHintTo = null;

    // 切换回合
    _isRedTurn = !_isRedTurn;

    // 开始新回合计时
    _startMoveTimer();

    // 更新FEN字符串
    _updateFenFromPieces();

    // 将当前状态加入历史记录（在移动之前保存）
    _fenHistory.add(_currentFen);

    // 记录移动
    _recordMove(fromX, fromY, toX, toY, movingPiece, targetPiece);

    // 检查游戏是否结束（将死、困毙等）
    await checkGameEnd();

    // 检查是否将军(移动后检查对方是否被将军)
    if (checkIfInCheckPure()) {
      debugPrint('⚠️ 将军!');
      _soundManager.playCheck(); // 播放将军音效
      // 通知 UI 显示将军提示
      _lastNotification = 'check';
    }

    // 通知状态变化
    _notifyStateChanged();

    debugPrint('✅ 移动成功: ${movingPiece.type} 从($fromX,$fromY) 到($toX,$toY)');
    debugPrint('=== 移动验证结束 ===');
    debugPrint('');
    return true;
  }

  /// 获取指定位置的棋子
  ChessPiece? getPieceAt(int x, int y) {
    try {
      return _pieces.firstWhere((piece) => piece.x == x && piece.y == y);
    } catch (e) {
      return null;
    }
  }

  /// 检查坐标是否有效
  bool _isValidCoordinate(int x, int y) {
    return x >= 0 && x < 9 && y >= 0 && y < 10;
  }

  /// 检查棋子是否属于当前玩家
  bool _isCurrentPlayerPiece(ChessPiece piece) {
    return (_isRedTurn && piece.color == PieceColor.red) ||
        (!_isRedTurn && piece.color == PieceColor.black);
  }

  /// 使用AI引擎验证移动是否符合象棋规则
  /// 这是主要的规则验证方法，优先使用Pikafish引擎验证
  Future<bool> _validateMoveWithEngine(int fromX, int fromY, int toX, int toY,
      ChessPiece movingPiece, ChessPiece? targetPiece) async {
    // 第一层验证：基础逻辑检查（快速失败）
    final basicValidation = _performBasicValidation(
        fromX, fromY, toX, toY, movingPiece, targetPiece);
    if (!basicValidation.isValid) {
      debugPrint('基础验证失败: ${basicValidation.reason}');
      return false;
    }

    // 第二层验证：引擎权威验证
    final engineValidation =
        await _performEngineValidation(fromX, fromY, toX, toY);
    if (engineValidation != null) {
      if (engineValidation.isValid) {
        debugPrint('✅ 引擎验证通过: 走法符合象棋规则');
        return true;
      } else {
        debugPrint('❌ 引擎验证失败: ${engineValidation.reason}');
        return false;
      }
    }

    // 第三层验证：本地规则验证（引擎不可用时的备选方案）
    debugPrint('⚠️ 引擎不可用，使用本地规则验证');
    final localValidation =
        _isValidChessMove(movingPiece, fromX, fromY, toX, toY, targetPiece);
    if (localValidation) {
      debugPrint('✅ 本地规则验证通过');
    } else {
      debugPrint('❌ 本地规则验证失败');
    }
    return localValidation;
  }

  /// 基础验证：快速检查明显的无效移动
  ValidationResult _performBasicValidation(int fromX, int fromY, int toX,
      int toY, ChessPiece movingPiece, ChessPiece? targetPiece) {
    // 检查是否移动到相同位置
    if (fromX == toX && fromY == toY) {
      return const ValidationResult(false, '不能移动到相同位置');
    }

    // 检查是否试图吃己方棋子
    if (targetPiece != null && targetPiece.color == movingPiece.color) {
      return const ValidationResult(false, '不能吃己方棋子');
    }

    // 检查移动距离是否合理（防止明显错误的移动）
    final distance = (fromX - toX).abs() + (fromY - toY).abs();
    if (distance > 18) {
      // 象棋棋盘最大移动距离
      return const ValidationResult(false, '移动距离超出合理范围');
    }

    return const ValidationResult(true, '基础验证通过');
  }

  /// 引擎验证：使用Pikafish引擎进行权威验证
  Future<ValidationResult?> _performEngineValidation(
      int fromX, int fromY, int toX, int toY) async {
    // 使用AI引擎管理器进行验证
    final isValid = await _aiEngine.validateMoveWithEngine(
        _currentFen, fromX, fromY, toX, toY);

    if (isValid) {
      return const ValidationResult(true, '引擎确认走法合法');
    } else {
      return const ValidationResult(false, '引擎判定走法不合法');
    }
  }

  /// 增强的引擎验证方法，包含详细分析
  Future<bool> validateMoveWithAnalysis(
      int fromX, int fromY, int toX, int toY) async {
    final movingPiece = getPieceAt(fromX, fromY);
    if (movingPiece == null) {
      debugPrint('❌ 验证失败: 起始位置没有棋子');
      return false;
    }

    final targetPiece = getPieceAt(toX, toY);

    // debugPrint('🎯 开始详细走法验证...');
    // debugPrint(
    //     '📍 起始位置: ($fromX,$fromY) - ${movingPiece.type} (${movingPiece.color})');
    // debugPrint(
    //     '📍 目标位置: ($toX,$toY) - ${targetPiece?.type ?? "空"} ${targetPiece != null ? "(${targetPiece.color})" : ""}');

    final isValid = await _validateMoveWithEngine(
        fromX, fromY, toX, toY, movingPiece, targetPiece);

    if (isValid) {
      debugPrint('✅ 走法验证通过，可以执行移动');
    } else {
      debugPrint('❌ 走法验证失败，移动被阻止');
    }

    return isValid;
  }

  /// 验证移动是否符合象棋规则
  bool _isValidChessMove(ChessPiece piece, int fromX, int fromY, int toX,
      int toY, ChessPiece? targetPiece) {
    switch (piece.type) {
      case PieceType.king:
        return _moveValidator.isValidKingMove(piece, fromX, fromY, toX, toY);
      case PieceType.advisor:
        return _moveValidator.isValidAdvisorMove(piece, fromX, fromY, toX, toY);
      case PieceType.elephant:
        return _moveValidator.isValidElephantMove(
            piece, fromX, fromY, toX, toY);
      case PieceType.horse:
        return _moveValidator.isValidHorseMove(piece, fromX, fromY, toX, toY);
      case PieceType.rook:
        return _moveValidator.isValidRookMove(piece, fromX, fromY, toX, toY);
      case PieceType.cannon:
        return _moveValidator.isValidCannonMove(
            piece, fromX, fromY, toX, toY, targetPiece);
      case PieceType.pawn:
        return _moveValidator.isValidPawnMove(piece, fromX, fromY, toX, toY);
    }
  }

  /// 执行移动操作
  void _executMove(ChessPiece movingPiece, int fromX, int fromY, int toX,
      int toY, ChessPiece? targetPiece) {
    // 移除目标位置的棋子（如果有）
    if (targetPiece != null) {
      _pieces.removeWhere((piece) => piece.x == toX && piece.y == toY);
      // 播放吃子音效
      _soundManager.playCapture();
    } else {
      // 播放移动音效
      _soundManager.playMove();
    }

    // 移除起始位置的棋子
    _pieces.removeWhere((piece) => piece.x == fromX && piece.y == fromY);

    // 在目标位置添加移动后的棋子
    _pieces.add(movingPiece.copyWith(x: toX, y: toY));
  }

  /// 记录移动历史
  void _recordMove(int fromX, int fromY, int toX, int toY,
      ChessPiece movingPiece, ChessPiece? capturedPiece) {
    final String moveNotation = _generateMoveNotation(
        fromX, fromY, toX, toY, movingPiece, capturedPiece);
    _moveHistory.add(moveNotation);
  }

  /// 生成移动记录符号
  String _generateMoveNotation(int fromX, int fromY, int toX, int toY,
      ChessPiece movingPiece, ChessPiece? capturedPiece) {
    return FenManager.generateMoveNotationWithCapture(
        fromX, fromY, toX, toY, capturedPiece != null);
  }

  /// 从FEN字符串更新棋子列表
  void _updatePiecesFromFen() {
    // 传入当前的 _pieces，便于 FenManager 在解析时复用已有棋子的 id，
    // 从而在 UI 层保持元素稳定，避免不必要的整体重建动画。
    _pieces = FenManager.parseFenToPieces(_currentFen,
        previousPieces: List<ChessPiece>.from(_pieces));
  }

  /// 从棋子列表更新FEN字符串
  void _updateFenFromPieces() {
    _currentFen = FenManager.generateFenFromPieces(
        _pieces, _isRedTurn, _moveHistory.length);
  }

  /// 将棋子转换为FEN字符
  /// 重置游戏到初始状态
  void resetGame() {
    _currentFen =
        "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1";
    _isRedTurn = true;
    _gameState = GameState.playing;
    _moveHistory.clear();
    _fenHistory.clear();
    _fenHistory.add(_currentFen); // 添加初始状态
    _updatePiecesFromFen();

    // 重置计时器
    _gameStartTime = DateTime.now();
    // 清除AI提示
    _lastHintFrom = null;
    _lastHintTo = null;
    _currentMoveStartTime = DateTime.now();
    _redTotalTime = 0;
    _blackTotalTime = 0;
    _currentMoveTime = 0;

    // 清除最后一步移动标记
    _lastMoveFrom = null;
    _lastMoveTo = null;

    _notifyStateChanged();
  }

  /// 开始回合计时
  void _startMoveTimer() {
    _currentMoveStartTime = DateTime.now();
    _currentMoveTime = 0;
  }

  /// 记录当前回合用时
  void _recordMoveTime() {
    if (_currentMoveStartTime != null) {
      final elapsed =
          DateTime.now().difference(_currentMoveStartTime!).inMilliseconds;
      final totalTime = elapsed + _currentMoveTime;

      // 累加到对应玩家的总用时
      if (_isRedTurn) {
        _redTotalTime += totalTime;
      } else {
        _blackTotalTime += totalTime;
      }
    }
  }

  /// 撤销上一步移动
  Future<bool> undoLastMove() async {
    // 至少需要两个状态才能悔棋（当前状态和上一个状态）
    if (_fenHistory.length < 2) {
      return false;
    }

    // 移除当前状态
    _fenHistory.removeLast();

    // 恢复到上一个状态
    _currentFen = _fenHistory.last;

    debugPrint('');
    debugPrint('=== 悔棋操作 ===');
    debugPrint('📋 恢复到FEN: $_currentFen');

    // 解析FEN字符串更新游戏状态
    final fenParts = _currentFen.split(' ');
    if (fenParts.length >= 2) {
      _isRedTurn = fenParts[1] == 'w';
      debugPrint('🔄 当前回合: ${_isRedTurn ? "红方" : "黑方"}');
    }

    // 移除对应的移动记录
    if (_moveHistory.isNotEmpty) {
      _moveHistory.removeLast();
    }

    // 更新棋子状态
    _updatePiecesFromFen();

    // 重新开始回合计时
    _startMoveTimer();

    // 重置游戏状态为进行中
    _gameState = GameState.playing;

    // 检查悔棋后的游戏状态（可能悔棋到一个已经结束的局面）
    await checkGameEnd();

    debugPrint('✅ 悔棋完成');
    debugPrint('=== 悔棋结束 ===');
    debugPrint('');

    // 通知状态变化
    _notifyStateChanged();

    // 清除AI提示（如果存在）
    _lastHintFrom = null;
    _lastHintTo = null;
    _notifyStateChanged();

    return true;
  }

  /// 获取游戏统计信息
  Map<String, dynamic> getGameStats() {
    return {
      'totalMoves': _moveHistory.length,
      'currentPlayer': _isRedTurn ? '红方' : '黑方',
      'gameState': _gameState.toString(),
      'piecesCount': _pieces.length,
    };
  }

  // ========== UCI API 相关方法 ==========

  /// 初始化象棋引擎
  /// 启用或禁用AI对战
  Future<void> setAIEnabled(bool enabled) async {
    await _aiEngine.setAIEnabled(enabled);
  }

  /// 设置AI难度等级
  void setAIDifficultyLevel(int level) {
    _aiEngine.setAIDifficultyLevel(level);
  }

  /// 获取AI难度等级
  int get aiDifficultyLevel => _aiEngine.aiDifficultyLevel;

  /// 获取AI启用状态
  bool get isAIEnabled => _aiEngine.isAIEnabled;

  /// 获取AI推荐的最佳走法
  Future<String?> getAIBestMove() async {
    return await _aiEngine.getAIBestMove(_currentFen);
  }

  /// 获取指定难度的 AI 建议走法（不会改变当前持久化的 AI 设置）
  ///
  /// 功能：临时将引擎设置为指定难度并确保引擎已就绪，然后请求最佳走法，最后恢复之前的难度与启用状态。
  Future<String?> getHintFromEngine({int difficulty = 8}) async {
    // 检查AI是否正在计算中
    if (_aiEngine.isAIThinking) {
      debugPrint('⚠️  AI正在计算中，请稍候...');
      return 'AI_THINKING'; // 返回特殊标记
    }

    try {
      // 记录当前状态
      final prevEnabled = _aiEngine.isAIEnabled;
      final prevDifficulty = _aiEngine.aiDifficultyLevel;

      // 确保引擎已初始化
      if (!_aiEngine.isEngineInitialized) {
        await _aiEngine.initializeEngine();
      }

      // 临时启用 AI（若未启用）并设置指定难度
      if (!prevEnabled) {
        await _aiEngine.setAIEnabled(true);
      }
      _aiEngine.setAIDifficultyLevel(difficulty.clamp(1, 10));

      // 请求推荐走法
      final best = await _aiEngine.getAIBestMove(_currentFen);

      // 解析并保存提示（如果有）
      if (best != null && best.length == 4) {
        try {
          final fromFile = best[0];
          final fromRank = int.parse(best[1]);
          final toFile = best[2];
          final toRank = int.parse(best[3]);
          final fromX = fromFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
          final fromY = 9 - fromRank;
          final toX = toFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
          final toY = 9 - toRank;

          _lastHintFrom = Point(fromX, fromY);
          _lastHintTo = Point(toX, toY);
          // 通知 UI 刷新以高亮显示提示
          _notifyStateChanged();
        } catch (e) {
          debugPrint('解析AI提示失败: $e');
        }
      } else {
        // 清除提示
        _lastHintFrom = null;
        _lastHintTo = null;
        _notifyStateChanged();
      }

      // 恢复之前的设置
      _aiEngine.setAIDifficultyLevel(prevDifficulty);
      if (!prevEnabled) {
        await _aiEngine.setAIEnabled(false);
      }

      return best;
    } catch (e, st) {
      debugPrint('获取提示失败: $e');
      debugPrint('$st');
      return null;
    }
  }

  /// 切换红方 AI 模式（仅在开发模式使用）
  void toggleRedAI() {
    _redAIEnabled = !_redAIEnabled;
    debugPrint('🔄 红方 AI ${_redAIEnabled ? "已启用" : "已禁用"}');
    _notifyStateChanged();

    // 如果启用红方AI且当前轮到红方,立即触发走子
    if (_redAIEnabled && _isRedTurn && _gameState == GameState.playing) {
      debugPrint('🔴 红方AI已启用,立即开始走子...');
      Future.delayed(const Duration(milliseconds: 300), () async {
        await makeRedAIMove(difficulty: _redAIDifficulty);
      });
    }
  }

  /// 设置红方 AI 难度（仅在开发模式使用）
  void setRedAIDifficulty(int difficulty) {
    _redAIDifficulty = difficulty;
    debugPrint('🔧 红方 AI 难度已设置为: $difficulty');
  }

  /// 让AI执行走法
  Future<bool> makeAIMove() async {
    if (!_aiEngine.isAIEnabled || _isRedTurn) {
      debugPrint(
          '⏭️  跳过AI: enabled=${_aiEngine.isAIEnabled}, isRedTurn=$_isRedTurn');
      return false; // AI 只在黑方回合执行
    }

    debugPrint('🤖 ========== AI回合开始 ==========');
    debugPrint('AI开始思考...');

    // 尝试多次获取有效走法，最多重试3次
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      final aiMove = await getAIBestMove();
      // Special handling: Pikafish on some platforms may return special text like
      // "(none)" to indicate no legal move exists. Treat both null, empty or
      // the literal "(none)" as a "no move" candidate and query engine for
      // legal moves — if there are truly none, the game is over (checkmate/stalemate).
      if (aiMove == null || aiMove.isEmpty || aiMove == '(none)') {
        debugPrint('⚠️  AI未返回有效走法或报告无合法走法 ("$aiMove")，检查合法走法...');

        // Try to ask the engine for legal moves. If channel is available it
        // will return a list; if empty -> game over; otherwise retry.
        try {
          final legalMoves = await _aiEngine.getLegalMoves(_currentFen);
          if (legalMoves.isEmpty) {
            debugPrint('🔎 引擎返回合法走法为空：认为当前方无合法走法 -> 触发游戏结束检查');
            // If engine reports no legal moves, fall back to controller's
            // game-end checks (pieces + engine-side checks) to determine result.
            await checkGameEnd();
            return false;
          }
        } catch (e) {
          debugPrint('⚠️ 请求合法走法失败: $e (将继续重试)');
        }

        debugPrint('重试次数: ${retryCount + 1}/$maxRetries');
        retryCount++;
        continue;
      }

      debugPrint('🎯 AI选择走法: $aiMove (尝试 ${retryCount + 1}/$maxRetries)');

      // 解析UCI格式走法 (例如 "e2e4" -> fromX=4, fromY=1, toX=4, toY=3)
      if (aiMove.length != 4) {
        debugPrint('AI走法格式无效: $aiMove，重试...');
        retryCount++;
        continue;
      }

      try {
        // UCI 格式：文件(a-i) + 排(0-9)
        final fromFile = aiMove[0];
        final fromRank = int.parse(aiMove[1]);
        final toFile = aiMove[2];
        final toRank = int.parse(aiMove[3]);

        // 转换为棋盘坐标 (0-8 for X, 0-9 for Y)
        // 注意：Pikafish 的 Y 坐标从红方底线(rank 0)开始
        // 我们的棋盘 Y 坐标从黑方底线(y=0)开始
        // 所以需要翻转：Pikafish rank N -> 我们的 y = 9 - N
        final fromX = fromFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
        final fromY = 9 - fromRank; // 翻转 Y 坐标
        final toX = toFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
        final toY = 9 - toRank; // 翻转 Y 坐标

        debugPrint('AI走法坐标: 从($fromX,$fromY) 到($toX,$toY)');

        // 在执行前进行详细验证
        final moveValidation =
            await _validateAIMove(fromX, fromY, toX, toY, aiMove);
        if (!moveValidation.isValid) {
          debugPrint('AI走法验证失败: ${moveValidation.reason}，重试...');
          retryCount++;
          continue;
        }

        // 执行移动
        final success = await movePiece(fromX, fromY, toX, toY);

        if (success) {
          debugPrint('✅ AI走法执行成功: $aiMove');
          debugPrint('🤖 ========== AI回合完成 ==========');

          // 黑方AI走完后,如果红方AI启用,触发红方AI
          if (_redAIEnabled && _isRedTurn && _gameState == GameState.playing) {
            debugPrint('🔴 黑方AI走完,准备红方AI走子...');
            Future.delayed(const Duration(milliseconds: 500), () async {
              await makeRedAIMove(difficulty: _redAIDifficulty);
            });
          }

          return true;
        } else {
          debugPrint('❌ AI走法执行失败: $aiMove (移动验证不通过)');
          // 分析失败原因
          await _analyzeMovementFailure(fromX, fromY, toX, toY, aiMove);
          retryCount++;
        }
      } catch (e) {
        debugPrint('❌ 解析AI走法异常: $e');
        retryCount++;
      }
    }

    // 所有重试都失败了
    debugPrint('❌ AI走法完全失败 (已重试 $maxRetries 次)');
    debugPrint('🤖 ========== AI回合失败 ==========');
    await _handleAIMoveFailure();
    return false;
  }

  /// 让红方AI执行走法（仅开发模式使用）
  Future<bool> makeRedAIMove({int difficulty = 8}) async {
    if (!_redAIEnabled || !_isRedTurn) {
      debugPrint('⏭️  跳过红方AI: enabled=$_redAIEnabled, isRedTurn=$_isRedTurn');
      return false; // 红方AI只在红方回合执行
    }

    debugPrint('🔴 ========== 红方AI回合开始 ==========');
    debugPrint('红方AI开始思考... (难度: $difficulty)');

    // 尝试多次获取有效走法，最多重试3次
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      // 使用传入的难度参数
      final aiMove = await getHintFromEngine(difficulty: difficulty);
      if (aiMove == null || aiMove.isEmpty || aiMove == 'AI_THINKING') {
        debugPrint('⚠️  红方AI未返回有效走法，重试次数: ${retryCount + 1}/$maxRetries');
        retryCount++;
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      debugPrint('🎯 红方AI选择走法: $aiMove (尝试 ${retryCount + 1}/$maxRetries)');

      // 解析UCI格式走法 (例如 "e2e4" -> fromX=4, fromY=1, toX=4, toY=3)
      if (aiMove.length != 4) {
        debugPrint('红方AI走法格式无效: $aiMove，重试...');
        retryCount++;
        continue;
      }

      try {
        // UCI 格式：文件(a-i) + 排(0-9)
        final fromFile = aiMove[0];
        final fromRank = int.parse(aiMove[1]);
        final toFile = aiMove[2];
        final toRank = int.parse(aiMove[3]);

        // 转换为棋盘坐标
        final fromX = fromFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
        final fromY = 9 - fromRank; // 翻转 Y 坐标
        final toX = toFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
        final toY = 9 - toRank; // 翻转 Y 坐标

        debugPrint('红方AI走法坐标: 从($fromX,$fromY) 到($toX,$toY)');

        // 在执行前进行详细验证
        final moveValidation =
            await _validateAIMove(fromX, fromY, toX, toY, aiMove);
        if (!moveValidation.isValid) {
          debugPrint('红方AI走法验证失败: ${moveValidation.reason}，重试...');
          retryCount++;
          continue;
        }

        // 执行移动
        final success = await movePiece(fromX, fromY, toX, toY);

        if (success) {
          debugPrint('✅ 红方AI走法执行成功: $aiMove');
          debugPrint('🔴 ========== 红方AI回合完成 ==========');

          // 红方AI走完后,如果黑方AI启用,触发黑方AI
          if (_aiEngine.isAIEnabled &&
              !_isRedTurn &&
              _gameState == GameState.playing) {
            debugPrint('🤖 红方AI走完,准备黑方AI走子...');
            Future.delayed(const Duration(milliseconds: 500), () async {
              await makeAIMove();
            });
          }

          return true;
        } else {
          debugPrint('❌ 红方AI走法执行失败: $aiMove (移动验证不通过)');
          await _analyzeMovementFailure(fromX, fromY, toX, toY, aiMove);
          retryCount++;
        }
      } catch (e) {
        debugPrint('❌ 解析红方AI走法异常: $e');
        retryCount++;
      }
    }

    // 所有重试都失败了
    debugPrint('❌ 红方AI走法完全失败 (已重试 $maxRetries 次)');
    debugPrint('🔴 ========== 红方AI回合失败 ==========');
    return false;
  }

  /// 按 UCI 字符串直接执行一次走法，可强制以黑方身份执行（用于开局库首步）
  /// 如果 asBlack 为 true，则临时将回合和 FEN 设置为黑方以允许执行黑方走子。
  Future<bool> playUciMove(String uci, {bool asBlack = false}) async {
    if (uci.length != 4) return false;
    try {
      final fromFile = uci[0];
      final fromRank = int.parse(uci[1]);
      final toFile = uci[2];
      final toRank = int.parse(uci[3]);

      final fromX = fromFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final fromY = 9 - fromRank;
      final toX = toFile.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final toY = 9 - toRank;

      final prevTurn = _isRedTurn;
      final prevFen = _currentFen;

      if (asBlack) {
        // 修改内部回合状态
        _isRedTurn = false;
        // 同时修改 FEN 的回合标记，使引擎验证时认为当前是黑方走
        _currentFen = _currentFen.replaceFirst(' w ', ' b ');
        debugPrint('🔄 playUciMove: 临时切换为黑方回合 (FEN: $_currentFen)');
      }

      final success = await movePiece(fromX, fromY, toX, toY);

      if (!success) {
        // 恢复原有回合和 FEN
        _isRedTurn = prevTurn;
        _currentFen = prevFen;
        debugPrint('⚠️ playUciMove: 走法失败，已恢复原状态');
      }

      return success;
    } catch (e) {
      debugPrint('❌ playUciMove 解析或执行失败: $e');
      return false;
    }
  }

  /// 验证AI走法的详细信息
  Future<MoveValidationResult> _validateAIMove(
      int fromX, int fromY, int toX, int toY, String uciMove) async {
    // 检查坐标范围
    if (!_isValidCoordinate(fromX, fromY) || !_isValidCoordinate(toX, toY)) {
      return const MoveValidationResult(false, '坐标超出棋盘范围');
    }

    // 检查起始位置是否有棋子
    final movingPiece = getPieceAt(fromX, fromY);
    if (movingPiece == null) {
      return MoveValidationResult(false, '起始位置($fromX,$fromY)没有棋子');
    }

    // 检查是否是当前玩家的棋子
    if (!_isCurrentPlayerPiece(movingPiece)) {
      return const MoveValidationResult(false, '起始位置的棋子不属于当前玩家');
    }

    // 检查目标位置
    final targetPiece = getPieceAt(toX, toY);
    if (targetPiece != null && targetPiece.color == movingPiece.color) {
      return const MoveValidationResult(false, '目标位置有己方棋子');
    }

    // 使用 AI引擎管理器验证走法合法性
    final isValid = await _aiEngine.validateMoveWithEngine(
        _currentFen, fromX, fromY, toX, toY);

    if (isValid) {
      debugPrint('✅ 引擎验证通过');
      return const MoveValidationResult(true, '走法有效');
    } else {
      return const MoveValidationResult(false, '引擎判定走法不合法');
    }
  }

  /// 分析移动失败的原因
  Future<void> _analyzeMovementFailure(
      int fromX, int fromY, int toX, int toY, String uciMove) async {
    debugPrint('=== AI走法失败分析 ===');
    debugPrint('走法: $uciMove');
    debugPrint('坐标: ($fromX,$fromY) -> ($toX,$toY)');
    debugPrint('当前FEN: $_currentFen');
    debugPrint('当前轮次: ${_isRedTurn ? "红方" : "黑方"}');

    final piece = getPieceAt(fromX, fromY);
    if (piece != null) {
      debugPrint('移动棋子: ${piece.type} (${piece.color})');
    } else {
      debugPrint('起始位置无棋子');
    }

    final target = getPieceAt(toX, toY);
    if (target != null) {
      debugPrint('目标位置棋子: ${target.type} (${target.color})');
    } else {
      debugPrint('目标位置为空');
    }

    debugPrint('棋盘状态:');
    _printBoardState();
    debugPrint('=== 分析结束 ===');
  }

  /// 处理AI走法完全失败的情况
  Future<void> _handleAIMoveFailure() async {
    debugPrint('AI走法执行完全失败，启用应急处理');

    // 尝试获取所有合法走法
    try {
      final legalMoves = await _aiEngine.getLegalMoves(_currentFen);
      if (legalMoves.isNotEmpty) {
        debugPrint('当前位置的合法走法: ${legalMoves.join(", ")}');

        // 随机选择一个合法走法作为应急方案
        final emergencyMove = legalMoves.first;
        debugPrint('使用应急走法: $emergencyMove');

        if (emergencyMove.length == 4) {
          final fromX = emergencyMove[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
          final fromY = int.parse(emergencyMove[1]);
          final toX = emergencyMove[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
          final toY = int.parse(emergencyMove[3]);

          final success = await movePiece(fromX, fromY, toX, toY);
          debugPrint('应急走法执行结果: $success');

          if (success) {
            debugPrint('应急走法执行成功，游戏继续');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('获取合法走法失败: $e');
    }

    // 如果应急处理也失败，可能需要暂停AI或重置游戏状态
    debugPrint('AI完全无法移动，可能需要人工干预');
    _gameState = GameState.stalemate; // 标记为僵局状态
    _notifyStateChanged();
  }

  /// 打印当前棋盘状态（调试用）
  void _printBoardState() {
    for (int y = 0; y < 10; y++) {
      StringBuffer row = StringBuffer();
      for (int x = 0; x < 9; x++) {
        final piece = getPieceAt(x, y);
        if (piece == null) {
          row.write('.');
        } else {
          // 简化表示
          final colorChar = piece.color == PieceColor.red ? 'R' : 'B';
          final typeChar =
              piece.type.toString().substring(10, 11).toUpperCase();
          row.write('$colorChar$typeChar');
        }
      }
      debugPrint('第$y行: ${row.toString()}');
    }
  }

  /// 验证走法是否合法
  Future<bool> validateMove(int fromX, int fromY, int toX, int toY) async {
    if (!_aiEngine.isEngineInitialized) {
      return true; // 如果引擎未初始化，使用默认验证逻辑
    }

    return await _aiEngine.validateMoveWithEngine(
        _currentFen, fromX, fromY, toX, toY);
  }

  /// 获取当前位置的详细分析
  Future<EngineAnalysis?> getPositionAnalysis({
    int depth = 8,
    int timeLimit = 5000,
  }) async {
    return await _aiEngine.getPositionAnalysis(_currentFen,
        depth: depth, timeLimit: timeLimit);
  }

  /// 检查当前位置是否将军
  Future<bool> checkIfInCheck() async {
    // 使用纯 Dart 实现
    return checkIfInCheckPure();
  }

  /// 检查当前位置是否将军(纯 Dart 实现 - 反向检查算法)
  /// 从将/帅出发,检查是否被对方棋子攻击
  bool checkIfInCheckPure() {
    final currentColor = _isRedTurn ? PieceColor.red : PieceColor.black;
    return _checkDetector.isInCheck(currentColor);
  }

  /// 检查游戏是否结束
  Future<void> checkGameEnd() async {
    debugPrint('');
    debugPrint('🔍 检查游戏是否结束...');
    debugPrint('📋 当前FEN: $_currentFen');
    debugPrint('⚙️ 引擎初始化状态: ${_aiEngine.isEngineInitialized}');

    // 使用AI引擎管理器检查游戏结束
    final result = await _aiEngine.checkGameEnd(_currentFen, _pieces);

    if (result.isEnd) {
      if (result.isCheckmate) {
        _gameState = GameState.checkmate;
        debugPrint(
            '🏁 游戏结束: 将死！${result.winner != null ? "${result.winner!}胜利" : ""}');
      } else if (result.isStalemate) {
        _gameState = GameState.stalemate;
        debugPrint('🏁 游戏结束: 僵局/困毙');
      }
      _notifyStateChanged();
    } else {
      debugPrint('✅ 游戏继续进行');
    }
    debugPrint('');
  }

  /// 获取引擎信息
  Future<String> getEngineInfo() async {
    return await _aiEngine.getEngineInfo();
  }

  /// 评估当前局面
  /// 返回局面评分，正数表示红方占优，负数表示黑方占优
  Future<int> evaluatePosition() async {
    return await _aiEngine.evaluatePosition(_currentFen);
  }

  /// 重置引擎
  Future<void> resetEngine() async {
    await _aiEngine.resetEngine();
  }

  /// 获取AI状态信息
  Map<String, dynamic> getAIStatus() {
    return _aiEngine.getAIStatus();
  }

  /// 处理玩家移动后的逻辑（包括触发AI响应）
  Future<void> handlePlayerMove(int fromX, int fromY, int toX, int toY) async {
    // 执行玩家移动
    final moveSuccess = await movePiece(fromX, fromY, toX, toY);

    if (!moveSuccess) {
      return;
    }

    // 检查游戏是否结束
    await checkGameEnd();

    // 如果启用AI且轮到黑方（AI），让AI走棋
    if (_aiEngine.isAIEnabled &&
        !_isRedTurn &&
        _gameState == GameState.playing) {
      // 延迟一下，让用户看到自己的走法效果
      await Future.delayed(const Duration(milliseconds: 800));

      final aiMoveSuccess = await makeAIMove();

      if (aiMoveSuccess) {
        // 检查AI走法后的游戏状态
        await checkGameEnd();
      }
    }
  }

  /// 检查是否应该轮到AI下棋
  bool shouldAIMove() {
    return _aiEngine.isAIEnabled &&
        !_isRedTurn &&
        _gameState == GameState.playing;
  }
}
