import 'dart:math';
import '../models/masyu_game.dart';

class MasyuGenerator {
  final Random _rng;
  MasyuGenerator([int? seed]) : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  (MasyuPuzzle, List<List<EdgeState>>, List<List<EdgeState>>) generate({
    int rows = 7, int cols = 7,
  }) {
    // 最简单可靠的方法：硬编码一个 3x3 矩形环
    const r1 = 2, r2 = 4, c1 = 2, c2 = 4;
    final t = List.generate(rows, (_) => List.filled(cols, 0));

    // 顺时针矩形：正确角落类型
    // 上边 (r1,c1)~(r1,c2): 4=RD, 5=DL, 中间=2
    for (int c = c1; c <= c2; c++) {
      t[r1][c] = (c == c1) ? 4 : (c == c2 ? 5 : 2);
      t[r2][c] = (c == c1) ? 3 : (c == c2 ? 6 : 2);
    }
    for (int r = r1 + 1; r < r2; r++) {
      t[r][c1] = 1;
      t[r][c2] = 1;
    }

    final cells = List.generate(rows, (_) => List.filled(cols, CellType.empty));
    // 放棋子
    for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) {
      final v = t[r][c]; if (v == 0) continue;
      if (_isTurn(v)) {
        // 拐角 → 黑
        final dirs = _dirs(v);
        bool ok = true;
        for (final d in dirs) {
          final nr = r + d[0], nc = c + d[1];
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) { ok = false; break; }
          if (t[nr][nc] == 0 || _isTurn(t[nr][nc])) { ok = false; break; }
        }
        if (ok) cells[r][c] = CellType.black;
      } else {
        // 直行 → 白
        final dirs = _dirs(v);
        for (final d in dirs) {
          final nr = r + d[0], nc = c + d[1];
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && _isTurn(t[nr][nc])) {
            cells[r][c] = CellType.white; break;
          }
        }
      }
    }

    final puzzle = MasyuPuzzle(rows, cols, cells);
    final (h, v) = _typesToEdges(t, rows, cols);
    return (puzzle, h, v);
  }

  bool _isTurn(int v) => v >= 3;

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

  (List<List<EdgeState>>, List<List<EdgeState>>) _typesToEdges(
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
}
