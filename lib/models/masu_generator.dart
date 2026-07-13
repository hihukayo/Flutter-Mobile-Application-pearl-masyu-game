import 'dart:math';
import 'masyu_game.dart';

// ============================================================================
//  Masyu 生成器 — 蛇形哈密顿回路 + 棋子派生
//  不依赖求解器，毫秒级完成
// ============================================================================

class MasyuGenerator {
  final Random _rng;
  MasyuGenerator([int? seed]) : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  /// 返回 (棋盘CellType, 解hEdges, 解vEdges)
  (MasyuPuzzle, List<List<EdgeState>>, List<List<EdgeState>>) generate({
    int rows = 7, int cols = 7,
  }) {
    final (types, hEdges, vEdges) = _genSnake(rows, cols);
    final cells = _deriveClues(types, rows, cols);
    final puzzle = MasyuPuzzle(rows, cols, cells);
    _thinOut(puzzle, rows, cols);
    return (puzzle, hEdges, vEdges);
  }

  // ================================================================
  //  蛇形哈密顿回路（访问所有格子）
  // ================================================================

  (List<List<int>>, List<List<EdgeState>>, List<List<EdgeState>>) _genSnake(int rows, int cols) {
    // cell types 矩阵: 0=不在环, 1=垂直直行, 2=水平直行, 3-6=拐角
    final t = List.generate(rows, (_) => List.filled(cols, 0));

    // 蛇形路径: 偶数行→右, 奇数行→左
    for (int r = 0; r < rows; r++) {
      if (r % 2 == 0) {
        for (int c = 0; c < cols; c++) {
          if (c == 0) t[r][c] = (r == 0) ? 3 : 5; // 起/终点特殊处理
          else if (c == cols - 1) t[r][c] = (r == rows - 1) ? 4 : 6;
          else t[r][c] = 2; // 水平直行
        }
      } else {
        for (int c = cols - 1; c >= 0; c--) {
          if (c == cols - 1) t[r][c] = 4;
          else if (c == 0) t[r][c] = (r == rows - 1) ? 5 : 6;
          else t[r][c] = 2; // 水平直行
        }
      }
    }

    // 修正蛇形转弯处的类型
    for (int r = 1; r < rows; r++) {
      if (r % 2 == 1) {
        // 奇数行左端: 从上下来→类型1(垂直), 且和上一行右端形成拐角
        t[r][cols - 1] = 1;
        t[r - 1][cols - 1] = 1; // 修正上一行右端为垂直
      } else {
        // 偶数行左端: 从左上来→类型1
        t[r][0] = 1;
        t[r - 1][0] = 1;
      }
    }
    // 左上角和左下角
    t[0][0] = 3; // 起点: 右+下
    t[0][cols - 1] = 1; // 上右: 垂直
    if (rows > 1) t[1][cols - 1] = 1;
    t[rows - 1][0] = 5; // 左下: 左+上
    t[rows - 1][cols - 1] = 4; // 右下: 右+上

    // 连接终点到起点（最左边一列向下）
    for (int r = rows - 1; r > 0; r--) {
      if (t[r][0] == 0) t[r][0] = 1; // 垂直
    }

    // 清理: 确保所有非0格有2个方向
    for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++)
      if (t[r][c] == 0) t[r][c] = 1; // 剩余全设为垂直（补全回路）

    // 转边
    final (h, v) = _toEdges(t, rows, cols);
    return (t, h, v);
  }

  (List<List<EdgeState>>, List<List<EdgeState>>) _toEdges(
      List<List<int>> t, int rows, int cols) {
    final h = List.generate(rows + 1, (_) => List.filled(cols, EdgeState.none));
    final v = List.generate(rows, (_) => List.filled(cols + 1, EdgeState.none));
    for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) {
      final val = t[r][c]; if (val == 0) continue;
      if (val == 1 || val == 3 || val == 6) h[r][c] = EdgeState.line;
      if (val == 1 || val == 4 || val == 5) h[r + 1][c] = EdgeState.line;
      if (val == 2 || val == 5 || val == 6) v[r][c] = EdgeState.line;
      if (val == 2 || val == 3 || val == 4) v[r][c + 1] = EdgeState.line;
    }
    return (h, v);
  }

  // ================================================================
  //  棋子派生
  // ================================================================

  List<List<CellType>> _deriveClues(List<List<int>> t, int rows, int cols) {
    final cells = List.generate(rows, (_) => List.filled(cols, CellType.empty));
    for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) {
      final v = t[r][c]; if (v == 0) continue;
      if (_isTurn(v)) {
        // 拐角→黑: 邻格必须都是直行
        final dirs = _dirs(v);
        bool ok = true;
        for (final d in dirs) {
          final nr = r + d[0], nc = c + d[1];
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) { ok = false; break; }
          if (t[nr][nc] == 0 || _isTurn(t[nr][nc])) { ok = false; break; }
        }
        if (ok) cells[r][c] = CellType.black;
      } else {
        // 直行→白: 至少一邻格是拐角
        final dirs = _dirs(v);
        for (final d in dirs) {
          final nr = r + d[0], nc = c + d[1];
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && _isTurn(t[nr][nc])) {
            cells[r][c] = CellType.white; break;
          }
        }
      }
    }
    return cells;
  }

  bool _isTurn(int v) => v == 3 || v == 4 || v == 5 || v == 6;

  List<List<int>> _dirs(int v) {
    switch (v) {
      case 1: return [[-1, 0], [1, 0]];
      case 2: return [[0, -1], [0, 1]];
      case 3: return [[-1, 0], [0, 1]];
      case 4: return [[0, 1], [1, 0]];
      case 5: return [[1, 0], [0, -1]];
      case 6: return [[0, -1], [-1, 0]];
      default: return [];
    }
  }

  // ================================================================
  //  薄化
  // ================================================================

  void _thinOut(MasyuPuzzle puzzle, int rows, int cols) {
    final all = <List<int>>[];
    for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++)
      if (puzzle.cells[r][c] != CellType.empty) all.add([r, c]);
    if (all.length <= 8) return;
    all.shuffle(_rng);
    int wc = all.where((p) => puzzle.cells[p[0]][p[1]] == CellType.white).length;
    int bc = all.where((p) => puzzle.cells[p[0]][p[1]] == CellType.black).length;
    final target = (all.length * 0.45).round().clamp(6, all.length - 1);
    for (final p in all) {
      if (wc + bc <= target) break;
      final r = p[0], c = p[1];
      final saved = puzzle.cells[r][c];
      if (saved == CellType.white && wc <= 2) continue;
      if (saved == CellType.black && bc <= 2) continue;
      puzzle.cells[r][c] = CellType.empty;
      if (saved == CellType.white) wc--; else bc--;
    }
  }
}
