import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../models/chess_piece.dart';
import '../painters/chess_board_painter.dart';
import '../controllers/game_controller.dart';
import '../utils/snackbar_helper.dart';
import 'game_info_panel.dart';
import '../utils/board_image_loader.dart';
import '../utils/xiangqi_assets.dart';

/// 游戏棋盘 Widget
class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    this.aiEnabled = false,
    this.aiDifficulty = 5,
    this.onGameReset,
    this.onGameUndo,
    this.onGameControllerReady,
  });

  final bool aiEnabled;
  final int aiDifficulty;
  final VoidCallback? onGameReset;
  final VoidCallback? onGameUndo;
  final Function(GameController)? onGameControllerReady;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  /// 游戏控制器
  late GameController gameController;

  /// 当前选中的棋子
  ChessPiece? selectedPiece;

  /// 定时器，用于更新时间显示
  Timer? _timer;

  /// 棋盘背景图片
  ui.Image? _boardImage;

  /// 是否已显示游戏结束对话框（防止重复显示）
  bool _gameEndDialogShown = false;

  @override
  void initState() {
    super.initState();
    gameController = GameController(
      enableAI: widget.aiEnabled,
      aiDifficultyLevel: widget.aiDifficulty,
    );

    // 设置状态变化回调，当游戏状态改变时刷新UI
    gameController.setOnStateChanged(() {
      if (mounted) {
        debugPrint(
            '🔔 [GameBoard] 状态变化回调触发: gameState=${gameController.gameState}');
        setState(() {});

        // 检查是否有待消费的通知，并即时显示（例如将军）
        final note = gameController.consumeLastNotification();
        if (note != null) {
          if (note == 'check') {
            SnackBarHelper.showMessage(context, '将军！');
          }
        }

        // 检查游戏是否结束，如果结束则显示对话框
        if (gameController.gameState != GameState.playing &&
            !_gameEndDialogShown) {
          debugPrint('🎯 [GameBoard] 检测到游戏结束，准备显示对话框');
          // 使用 addPostFrameCallback 确保在 setState 完成后显示对话框
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_gameEndDialogShown) {
              debugPrint('🎬 [GameBoard] 显示游戏结束对话框');
              _gameEndDialogShown = true;
              _showGameEndDialog();
            }
          });
        }
      }
    });

    // 启动定时器，每秒更新一次UI以刷新时间显示
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // 将 GameController 传递给父组件
    widget.onGameControllerReady?.call(gameController);

    // 加载棋盘背景图片
    _loadBoardImage();

    // 预缓存棋子图片，避免首次显示卡顿 - 延迟执行降低启动负载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 延迟200ms后再缓存图片,让UI先渲染出来
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        // 统一从 XiangqiAssets 获取资源列表并缓存
        for (final path in XiangqiAssets.allPieceAssets) {
          precacheImage(AssetImage(path), context);
        }
      });
    });

    // 初始化后检查游戏状态（处理初始局面或悔棋后的结束状态）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await gameController.checkGameEnd();
    });
  }

  /// 加载棋盘背景图片
  Future<void> _loadBoardImage() async {
    final image = await BoardImageLoader.loadBoardImage();
    if (mounted && image != null) {
      setState(() {
        _boardImage = image;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 处理触摸按下事件
  void _handleTapDown(
      TapDownDetails details, double boardWidth, double boardHeight) {
    // 获取用户点击的相对于GestureDetector的坐标
    final Offset localPosition = details.localPosition;

    debugPrint('');
    debugPrint('=== 触摸事件 ===');
    debugPrint(
        '屏幕坐标: (${localPosition.dx.toStringAsFixed(1)}, ${localPosition.dy.toStringAsFixed(1)})');
    debugPrint(
        '棋盘尺寸: ${boardWidth.toStringAsFixed(1)} x ${boardHeight.toStringAsFixed(1)}');

    // 转换为棋盘逻辑坐标
    final boardCoordinates = _screenToBoardCoordinates(
      localPosition,
      boardWidth,
      boardHeight,
    );

    if (boardCoordinates != null) {
      debugPrint(
          '棋盘坐标: (${boardCoordinates.dx.toInt()}, ${boardCoordinates.dy.toInt()})');
      _handleBoardTap(boardCoordinates.dx.toInt(), boardCoordinates.dy.toInt());
    } else {
      debugPrint('❌ 坐标转换失败: 点击位置超出棋盘范围');
    }
    debugPrint('=== 触摸事件结束 ===');
    debugPrint('');
  }

  /// 将屏幕坐标转换为棋盘逻辑坐标
  Offset? _screenToBoardCoordinates(
      Offset screenPosition, double boardWidth, double boardHeight) {
    // 计算边距和实际棋盘尺寸
    final double pieceMargin = (boardWidth + boardHeight) * 0.028; // 调整边距
    final double actualBoardWidth = boardWidth - 2 * pieceMargin;
    final double actualBoardHeight = boardHeight - 2 * pieceMargin;

    // 棋盘有9条竖线和10条横线，形成8×9个格子
    // 但棋子位置是基于交叉点的，所以是9×10个位置点
    final double cellWidth = actualBoardWidth / 8; // 8个格子宽度，9个交叉点
    final double cellHeight = actualBoardHeight / 9; // 9个格子高度，10个交叉点

    // 调整点击坐标，减去边距
    final double adjustedX = screenPosition.dx - pieceMargin;
    final double adjustedY = screenPosition.dy - pieceMargin;

    // 计算逻辑坐标 - 基于交叉点
    final double x = adjustedX / cellWidth;
    final double y = adjustedY / cellHeight;

    // 先四舍五入到最近的交叉点
    final int roundedX = x.round();
    final int roundedY = y.round();

    // 检查四舍五入后的坐标是否在有效范围内
    if (roundedX >= 0 && roundedX <= 8 && roundedY >= 0 && roundedY <= 9) {
      return Offset(roundedX.toDouble(), roundedY.toDouble());
    }

    return null; // 无效坐标
  }

  /// 处理棋盘点击事件（重构后的逻辑）
  void _handleBoardTap(int x, int y) {
    debugPrint('👆 点击棋盘: ($x, $y)');
    final tappedPiece = gameController.getPieceAt(x, y);

    if (tappedPiece != null) {
      debugPrint(
          '  点击位置有棋子: ${tappedPiece.type} ${tappedPiece.color} at ($x, $y)');
    } else {
      debugPrint('  点击位置为空');
    }

    debugPrint('  当前回合: ${gameController.isRedTurn ? "红方" : "黑方"}');
    debugPrint(
        '  已选择棋子: ${selectedPiece != null ? "${selectedPiece!.type} ${selectedPiece!.color} at (${selectedPiece!.x}, ${selectedPiece!.y})" : "无"}');

    if (selectedPiece == null) {
      // 第一次点击：选择棋子
      if (tappedPiece != null && _isCurrentPlayerPiece(tappedPiece)) {
        debugPrint('  ✅ 选择棋子: ${tappedPiece.type} at ($x, $y)');
        setState(() {
          selectedPiece = tappedPiece;
        });
      } else if (tappedPiece != null) {
        debugPrint('  ❌ 不能选择对方棋子');
      } else {
        debugPrint('  ❌ 点击位置无棋子');
      }
    } else {
      // 第二次点击：移动棋子或重新选择
      if (tappedPiece != null && tappedPiece == selectedPiece) {
        // 点击同一棋子，取消选择
        debugPrint('  🔄 取消选择');
        setState(() {
          selectedPiece = null;
        });
      } else if (tappedPiece != null && _isCurrentPlayerPiece(tappedPiece)) {
        // 点击当前玩家的其他棋子，切换选择
        debugPrint('  🔄 切换选择: ${tappedPiece.type} at ($x, $y)');
        setState(() {
          selectedPiece = tappedPiece;
        });
      } else {
        // 点击空位或敌方棋子，尝试移动
        debugPrint(
            '  🚀 尝试移动: ${selectedPiece!.type} 从(${selectedPiece!.x}, ${selectedPiece!.y}) 到($x, $y)');
        _attemptMove(selectedPiece!, x, y);
      }
    }
  }

  /// 尝试移动棋子
  void _attemptMove(ChessPiece piece, int toX, int toY) async {
    debugPrint(
        '📍 开始尝试移动: ${piece.type} 从(${piece.x}, ${piece.y}) 到($toX, $toY)');

    // 使用GameController的统一方法处理玩家移动
    await gameController.handlePlayerMove(piece.x, piece.y, toX, toY);

    debugPrint('📍 移动处理完成');

    // 清除选择（状态变化回调会自动刷新UI）
    setState(() {
      selectedPiece = null;
    });

    // 如果游戏结束，显示结果
    if (gameController.gameState != GameState.playing && !_gameEndDialogShown) {
      _gameEndDialogShown = true;
      _showGameEndDialog();
    }
  }

  /// 显示游戏结束对话框
  void _showGameEndDialog() {
    debugPrint(
        '📢 [GameBoard] _showGameEndDialog 被调用，gameState=${gameController.gameState}');
    String title;
    String message;

    switch (gameController.gameState) {
      case GameState.checkmate:
        title = '游戏结束';
        message = gameController.isRedTurn ? '黑方胜利！' : '红方胜利！';
        debugPrint('✅ [GameBoard] 将死对话框: $message');
        break;
      case GameState.stalemate:
        title = '和棋';
        message = '无法继续移动，游戏平局';
        debugPrint('✅ [GameBoard] 困毙对话框: $message');
        break;
      case GameState.draw:
        title = '平局';
        message = '游戏平局';
        debugPrint('✅ [GameBoard] 平局对话框: $message');
        break;
      default:
        debugPrint('⚠️ [GameBoard] 游戏状态不是结束状态，跳过对话框');
        return; // 游戏未结束，不显示对话框
    }

    debugPrint('🎨 [GameBoard] 准备显示 showDialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('重新开始'),
            ),
          ],
        );
      },
    );
  }

  /// 重置游戏
  void _resetGame() {
    setState(() {
      gameController.resetGame();
      selectedPiece = null;
      _gameEndDialogShown = false; // 重置对话框标志
    });
    // 调用外部回调
    widget.onGameReset?.call();
  }

  /// 判断棋子是否属于当前玩家
  bool _isCurrentPlayerPiece(ChessPiece piece) {
    return (gameController.isRedTurn && piece.color == PieceColor.red) ||
        (!gameController.isRedTurn && piece.color == PieceColor.black);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, boxConstraints) {
        return Column(
          children: [
            // 游戏信息面板
            GameInfoPanel(
              gameController: gameController,
              aiEnabled: widget.aiEnabled,
              aiDifficulty: widget.aiDifficulty,
            ),

            // 棋盘
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 增大棋盘尺寸，减少边距
                  const double marginRatio = 0.01; // 进一步减少边距到1%
                  final double maxWidth =
                      constraints.maxWidth * (1 - marginRatio * 2);
                  final double maxHeight =
                      constraints.maxHeight * (1 - marginRatio * 2);

                  double boardWidth;
                  double boardHeight;

                  // 计算棋盘尺寸，优先使用更大的尺寸
                  if (maxWidth / maxHeight > 8 / 9) {
                    // 高度受限，但要确保棋盘足够大
                    boardHeight = maxHeight;
                    boardWidth = boardHeight * 8 / 9;
                  } else {
                    // 宽度受限
                    boardWidth = maxWidth;
                    boardHeight = boardWidth * 9 / 8;

                    // 如果计算出的高度超出可用空间，重新按高度计算
                    if (boardHeight > maxHeight) {
                      boardHeight = maxHeight;
                      boardWidth = boardHeight * 8 / 9;
                    }
                  }

                  return Align(
                    alignment: Alignment.center, // 改为居中对齐
                    child: SizedBox(
                      width: boardWidth,
                      height: boardHeight,
                      child: GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          _handleTapDown(details, boardWidth, boardHeight);
                        },
                        child: Stack(
                          children: [
                            // 底层：棋盘
                            CustomPaint(
                              size: Size(boardWidth, boardHeight),
                              painter: ChessBoardPainter(
                                boardWidth: boardWidth,
                                boardHeight: boardHeight,
                                boardImage: _boardImage,
                              ),
                            ),
                            // 上层：棋子显示
                            _buildPiecesLayer(boardWidth, boardHeight),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建棋子层
  Widget _buildPiecesLayer(double boardWidth, double boardHeight) {
    // 与棋盘绘制器保持一致的边距计算
    final double pieceMargin = (boardWidth + boardHeight) * 0.028; // 调整边距
    final double actualBoardWidth = boardWidth - 2 * pieceMargin;
    final double actualBoardHeight = boardHeight - 2 * pieceMargin;
    final double cellWidth = actualBoardWidth / 8;
    final double cellHeight = actualBoardHeight / 9;

    final double pieceSize = (cellWidth + cellHeight) * 0.45;

    return Stack(
      children: [
        // 最后一步移动的标记（在棋子下方）
        if (gameController.lastMoveFrom != null)
          _buildMoveMarker(
            gameController.lastMoveFrom!.x,
            gameController.lastMoveFrom!.y,
            cellWidth,
            cellHeight,
            pieceMargin,
          ),
        if (gameController.lastMoveTo != null)
          _buildMoveMarker(
            gameController.lastMoveTo!.x,
            gameController.lastMoveTo!.y,
            cellWidth,
            cellHeight,
            pieceMargin,
          ),

        // AI 提示标记（渲染在棋子下方作为环形提示，避免遮挡棋子）
        if (gameController.lastHintFrom != null)
          _buildHintMarker(
            gameController.lastHintFrom!.x,
            gameController.lastHintFrom!.y,
            cellWidth,
            cellHeight,
            pieceMargin,
            pieceSize,
          ),
        if (gameController.lastHintTo != null)
          _buildHintMarker(
            gameController.lastHintTo!.x,
            gameController.lastHintTo!.y,
            cellWidth,
            cellHeight,
            pieceMargin,
            pieceSize,
          ),

        // 棋子显示
        ...gameController.pieces.map((piece) => _buildPieceWidget(
              piece,
              cellWidth,
              cellHeight,
              pieceMargin,
              pieceSize,
            )),

        // 选中棋子的可移动位置提示
        if (selectedPiece != null) ..._buildMoveHints(cellWidth, cellHeight),
      ],
    );
  }

  /// 构建 AI 提示标记（绿色高亮）
  Widget _buildHintMarker(int x, int y, double cellWidth, double cellHeight,
      double pieceMargin, double pieceSize) {
    // markerSize slightly larger than the piece so ring appears around it
    final double markerSize = pieceSize * 1.0;

    return Positioned(
      left: pieceMargin + x * cellWidth - markerSize / 2,
      top: pieceMargin + y * cellHeight - markerSize / 2,
      width: markerSize,
      height: markerSize,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.greenAccent.shade400, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withAlpha((0.6 * 255).round()),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个棋子Widget
  Widget _buildPieceWidget(ChessPiece piece, double cellWidth,
      double cellHeight, double pieceMargin, double pieceSize) {
    final isSelected = selectedPiece == piece;

    // 传入了 pieceSize 与 pieceMargin，避免重复计算

    return AnimatedPositioned(
      key: ValueKey(
          piece.id), // 使用稳定的 id 作为 key，以便 AnimatedPositioned 在位置变化时执行动画
      left: pieceMargin + piece.x * cellWidth - pieceSize / 2,
      top: pieceMargin + piece.y * cellHeight - pieceSize / 2,
      width: pieceSize,
      height: pieceSize,
      duration: const Duration(milliseconds: 300), // 动画时长
      curve: Curves.easeInOut, // 动画曲线
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // 选中时添加黄色高亮背景
            color: isSelected
                ? Colors.yellow[200]?.withAlpha((0.7 * 255).round())
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: Colors.orange[600]!, width: 4)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.orange.withAlpha((0.5 * 255).round()),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _buildPieceDisplay(piece, cellWidth, cellHeight, pieceSize),
          ),
        ),
      ),
    );
  }

  /// 构建棋子显示内容
  Widget _buildPieceDisplay(
      ChessPiece piece, double cellWidth, double cellHeight, double pieceSize) {
    // 直接使用 Image.asset，异常时回退到文字显示
    return ClipOval(
      child: SizedBox(
        width: pieceSize,
        height: pieceSize,
        child: Image.asset(
          piece.assetPath,
          fit: BoxFit.cover,
          width: pieceSize,
          height: pieceSize,
          errorBuilder: (context, error, stackTrace) {
            return _buildTextPiece(piece, cellWidth, cellHeight);
          },
        ),
      ),
    );
  }

  /// 构建文字棋子
  Widget _buildTextPiece(
      ChessPiece piece, double cellWidth, double cellHeight) {
    // 棋子填满容器
    return Container(
      decoration: _pieceDecoration(piece, cellWidth, cellHeight),
      child: Center(
        child: Text(
          piece.chineseName,
          style: _pieceTextStyle(piece, cellWidth, cellHeight),
        ),
      ),
    );
  }

  /// 辅助：生成棋子文字样式
  TextStyle _pieceTextStyle(
      ChessPiece piece, double cellWidth, double cellHeight) {
    return TextStyle(
      fontSize: (cellWidth + cellHeight) * 0.15,
      fontWeight: FontWeight.w900,
      color: piece.color == PieceColor.red
          ? const Color(0xFFDC143C)
          : Colors.white,
      shadows: [
        Shadow(
          offset: const Offset(1, 1),
          blurRadius: 2,
          color: piece.color == PieceColor.red
              ? Colors.black.withAlpha((0.3 * 255).round())
              : Colors.black.withAlpha((0.5 * 255).round()),
        ),
      ],
    );
  }

  /// 辅助：生成棋子背景装饰
  BoxDecoration _pieceDecoration(
      ChessPiece piece, double cellWidth, double cellHeight) {
    final isSelected = selectedPiece == piece;
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isSelected
          ? Colors.yellow[200]?.withAlpha((0.7 * 255).round())
          : (piece.color == PieceColor.red
              ? const Color(0xFFF5DEB3)
              : const Color(0xFF8B4513)),
      border: isSelected
          ? Border.all(color: Colors.orange[600]!, width: 4)
          : Border.all(color: Colors.black, width: 2.5),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: Colors.orange.withAlpha((0.5 * 255).round()),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withAlpha((0.4 * 255).round()),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
    );
  }

  /// 构建移动提示 - 显示选中棋子可移动的位置
  List<Widget> _buildMoveHints(double cellWidth, double cellHeight) {
    if (selectedPiece == null) return [];

    // 获取选中棋子的可移动位置（本地规则计算，无需异步）
    final legalMoves = gameController.getLegalMovesForPiece(
      selectedPiece!.x,
      selectedPiece!.y,
    );

    if (legalMoves.isEmpty) return [];

    // 计算边距，与 _buildPiecesLayer 保持一致
    final double boardWidth =
        cellWidth * 8 + 2 * ((cellWidth * 8 + cellHeight * 9) * 0.028);
    final double boardHeight =
        cellHeight * 9 + 2 * ((cellWidth * 8 + cellHeight * 9) * 0.028);
    final double pieceMargin = (boardWidth + boardHeight) * 0.028;

    // 提示点的大小
    final double hintSize = (cellWidth + cellHeight) * 0.15;

    return legalMoves.map((point) {
      return Positioned(
        left: pieceMargin + point.x * cellWidth - hintSize / 2,
        top: pieceMargin + point.y * cellHeight - hintSize / 2,
        width: hintSize,
        height: hintSize,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromRGBO(162, 80, 209, 0.7),
            border: Border.all(
              color: const Color.fromRGBO(162, 80, 209, 1),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(162, 80, 209, 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// 构建移动标记（红色边角）
  Widget _buildMoveMarker(
    int x,
    int y,
    double cellWidth,
    double cellHeight,
    double pieceMargin,
  ) {
    // 棋子大小
    final double pieceSize = (cellWidth + cellHeight) * 0.45;

    // 标记尺寸（略大于棋子）
    final double markerSize = pieceSize * 0.85;

    // 边角线的长度和宽度
    final double cornerLength = markerSize * 0.07;
    const double cornerWidth = 3.0;

    return Positioned(
      left: pieceMargin + x * cellWidth - markerSize / 2,
      top: pieceMargin + y * cellHeight - markerSize / 2,
      width: markerSize,
      height: markerSize,
      child: CustomPaint(
        painter: _MoveMarkerPainter(
          cornerLength: cornerLength,
          cornerWidth: cornerWidth,
        ),
      ),
    );
  }
}

/// 移动标记绘制器 - 绘制四个带颜色边角
class _MoveMarkerPainter extends CustomPainter {
  final double cornerLength;
  final double cornerWidth;

  _MoveMarkerPainter({
    required this.cornerLength,
    required this.cornerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(162, 80, 209, 1)
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 左上角
    canvas.drawLine(
      const Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, cornerLength),
      paint,
    );

    // 右上角
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // 左下角
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // 右下角
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
