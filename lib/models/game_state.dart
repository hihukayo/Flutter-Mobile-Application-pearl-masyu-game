import 'constants.dart';

// ============================================================================
//  GameState — 移植 pearl.c 第119-134行
// ============================================================================

class GameState {
  final int w, h;
  final List<ClueType> clues; // 线索数组 size=w*h
  List<EdgeState> lines;      // 线段状态 size=w*h
  List<EdgeState> errors;     // 错误标记
  bool completed = false;
  bool usedSolve = false;

  GameState(this.w, this.h, this.clues)
      : lines = List.filled(w * h, EdgeState.blank),
        errors = List.filled(w * h, EdgeState.blank);

  int get sz => w * h;

  ClueType clueAt(int x, int y) => clues[y * w + x];
  EdgeState lineAt(int x, int y) => lines[y * w + x];

  /// 从 CellType 矩阵创建 GameState
  factory GameState.fromCellTypes(List<List<CellType>> cells) {
    final h = cells.length, w = cells[0].length;
    final clues = List.generate(w * h, (i) {
      final r = i ~/ w, c = i % w;
      if (cells[r][c] == CellType.black) return ClueType.corner;
      if (cells[r][c] == CellType.white) return ClueType.straight;
      return ClueType.none;
    });
    return GameState(w, h, clues);
  }

  /// 转为 CellType 矩阵
  List<List<CellType>> toCellTypes() {
    return List.generate(h, (r) =>
        List.generate(w, (c) {
          if (clues[r * w + c] == ClueType.corner) return CellType.black;
          if (clues[r * w + c] == ClueType.straight) return CellType.white;
          return CellType.empty;
        }));
  }
}

// 兼容旧版枚举
enum CellType { empty, white, black }
