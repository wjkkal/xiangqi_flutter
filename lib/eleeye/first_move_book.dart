import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

class FirstMoveEntry {
  final String move;
  final int count;
  FirstMoveEntry(this.move, this.count);
}

Future<List<FirstMoveEntry>> loadStartFirstMoves([
  String assetPath = 'assets/openings_eleeye_first_moves.json',
]) async {
  try {
    final str = await rootBundle.loadString(assetPath);
    final j = jsonDecode(str) as Map<String, dynamic>;
    final arr = (j['start'] as List).cast<Map<String, dynamic>>();
    try {
      debugPrint('📦 已加载开局首步资产: $assetPath, 条数=${arr.length}');
    } catch (_) {}
    return arr
        .map((m) =>
            FirstMoveEntry(m['move'] as String, (m['count'] as num).toInt()))
        .toList();
  } catch (e) {
    try {
      debugPrint('❌ 无法加载开局首步资产: $assetPath -> $e');
    } catch (_) {}
    return [];
  }
}

String _flipMoveVertical(String mv) {
  if (mv.length != 4) return mv;
  final fromFile = mv[0];
  final fromRank = int.tryParse(mv[1]) ?? 0;
  final toFile = mv[2];
  final toRank = int.tryParse(mv[3]) ?? 0;
  final newFromRank = 9 - fromRank;
  final newToRank = 9 - toRank;
  return '$fromFile$newFromRank$toFile$newToRank';
}

/// 按方位加载首步候选，优先尝试双向资产（包含 red/black），不存在时回退到单侧并在需要时翻转
Future<List<FirstMoveEntry>> loadStartFirstMovesForSide(bool forRed,
    [String assetPath = 'assets/openings_eleeye_first_moves.json']) async {
  const bothPath = 'assets/openings_eleeye_first_moves_both.json';
  try {
    final str = await rootBundle.loadString(bothPath);
    final j = jsonDecode(str) as Map<String, dynamic>;
    final key = forRed ? 'red' : 'black';
    final arr = (j[key] as List?) ?? <dynamic>[];
    try {
      debugPrint('📦 已加载双向开局首步资产: $bothPath, side=$key, 条数=${arr.length}');
    } catch (_) {}
    return arr
        .map((m) =>
            FirstMoveEntry(m['move'] as String, (m['count'] as num).toInt()))
        .toList();
  } catch (_) {
    final list = await loadStartFirstMoves(assetPath);
    try {
      debugPrint('📦 使用单侧资产回退: $assetPath, 返回条数=${list.length}');
    } catch (_) {}
    if (!forRed && list.isNotEmpty) {
      return list
          .map((e) => FirstMoveEntry(_flipMoveVertical(e.move), e.count))
          .toList();
    }
    return list;
  }
}
