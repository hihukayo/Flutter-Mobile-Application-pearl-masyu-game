import 'dart:math';
import 'masyu_game.dart';

// ============================================================================
//  Masyu 求解器 v5 — dot-to-dot 边模型
// ============================================================================

const _R = {2, 3, 4};
const _L = {2, 5, 6};
const _D = {1, 4, 5};
const _U = {1, 3, 6};
const _turns = {3, 4, 5, 6};
const _straights = {1, 2};

class MasyuSolver {
  static (List<List<EdgeState>>, List<List<EdgeState>>)? solve(MasyuPuzzle puzzle) {
    final rows = puzzle.rows, cols = puzzle.cols;
    final cells = List.generate(rows, (_) => List.generate(cols, (_) => <int>{0, 1, 2, 3, 4, 5, 6}));

    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++) {
        if (puzzle.cells[r][c] != CellType.empty) cells[r][c].remove(0);
        if (puzzle.cells[r][c] == CellType.white) cells[r][c].removeAll(_turns);
        if (puzzle.cells[r][c] == CellType.black) cells[r][c].removeAll(_straights);
      }

    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++) {
        if (r == 0) cells[r][c].removeAll(_U);
        if (r == rows - 1) cells[r][c].removeAll(_D);
        if (c == 0) cells[r][c].removeAll(_L);
        if (c == cols - 1) cells[r][c].removeAll(_R);
      }

    if (!_ac3(cells, rows, cols)) return null;
    if (!_search(cells, rows, cols, puzzle.cells)) return null;
    return _toEdges(cells, rows, cols);
  }

  static bool _ac3(List<List<Set<int>>> cells, int rows, int cols) {
    final q = <List<int>>[];
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++) {
        if (c < cols - 1) { q.add([r, c, r, c + 1]); q.add([r, c + 1, r, c]); }
        if (r < rows - 1) { q.add([r, c, r + 1, c]); q.add([r + 1, c, r, c]); }
      }
    while (q.isNotEmpty) {
      final a = q.removeLast();
      if (_revise(cells, a[0], a[1], a[2], a[3])) {
        if (cells[a[0]][a[1]].isEmpty) return false;
        for (final nb in _near(a[0], a[1], rows, cols))
          if (nb[0] != a[2] || nb[1] != a[3]) q.add([nb[0], nb[1], a[0], a[1]]);
      }
    }
    return true;
  }

  static bool _revise(List<List<Set<int>>> cells, int ra, int ca, int rb, int cb) {
    bool changed = false;
    final horiz = ra == rb;
    for (final a in Set<int>.from(cells[ra][ca])) {
      bool ok = false;
      for (final b in cells[rb][cb])
        if (horiz ? (_R.contains(a)) == (_L.contains(b)) : (_D.contains(a)) == (_U.contains(b))) { ok = true; break; }
      if (!ok) { cells[ra][ca].remove(a); changed = true; }
    }
    return changed;
  }

  static bool _search(List<List<Set<int>>> c, int rows, int cols, List<List<CellType>> types) {
    if (!_ac3(c, rows, cols)) return false;
    int br = -1, bc = -1, bs = 999;
    for (int r = 0; r < rows; r++)
      for (int cc = 0; cc < cols; cc++)
        if (c[r][cc].length > 1 && c[r][cc].length < bs) { br = r; bc = cc; bs = c[r][cc].length; }
    if (br == -1) return _verifyAll(c, rows, cols, types);
    if (bs >= 6) {
      bool allPearlsDone = true;
      outer:
      for (int r = 0; r < rows; r++)
        for (int cc = 0; cc < cols; cc++)
          if (types[r][cc] != CellType.empty && c[r][cc].length > 1) { allPearlsDone = false; break outer; }
      if (allPearlsDone) {
        final b2 = _clone(c, rows, cols);
        for (int r = 0; r < rows; r++)
          for (int cc = 0; cc < cols; cc++)
            if (c[r][cc].length > 1) c[r][cc] = {0};
        if (_ac3(c, rows, cols) && _verifyAll(c, rows, cols, types)) return true;
        _restore(c, b2, rows, cols);
      }
    }
    final bak = _clone(c, rows, cols);
    for (final v in c[br][bc].toList()..sort()) {
      c[br][bc] = {v};
      if (_search(c, rows, cols, types)) return true;
      _restore(c, bak, rows, cols);
    }
    return false;
  }

  static bool _verifyAll(List<List<Set<int>>> cells, int rows, int cols, List<List<CellType>> types) {
    final loop = <List<int>>[];
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++)
        if (cells[r][c].first != 0) loop.add([r, c]);
    if (loop.length < 4) return false;
    int cr = loop[0][0], cc = loop[0][1], pr = -1, pc = -1, v = 0;
    do {
      v++;
      if (v > rows * cols * 2) return false;
      final t = cells[cr][cc].first;
      int nr = -1, nc = -1;
      if (t == 1) {
        if (cr > 0 && !(cr - 1 == pr && cc == pc)) nr = cr - 1; else if (cr < rows - 1) nr = cr + 1; nc = cc;
      } else if (t == 2) {
        if (cc > 0 && !(cr == pr && cc - 1 == pc)) nc = cc - 1; else if (cc < cols - 1) nc = cc + 1; nr = cr;
      } else if (t == 3) {
        if (cr > 0 && !(cr - 1 == pr && cc == pc)) { nr = cr - 1; nc = cc; } else if (cc < cols - 1) { nr = cr; nc = cc + 1; }
      } else if (t == 4) {
        if (cc < cols - 1 && !(cr == pr && cc + 1 == pc)) { nr = cr; nc = cc + 1; } else if (cr < rows - 1) { nr = cr + 1; nc = cc; }
      } else if (t == 5) {
        if (cr < rows - 1 && !(cr + 1 == pr && cc == pc)) { nr = cr + 1; nc = cc; } else if (cc > 0) { nr = cr; nc = cc - 1; }
      } else if (t == 6) {
        if (cc > 0 && !(cr == pr && cc - 1 == pc)) { nr = cr; nc = cc - 1; } else if (cr > 0) { nr = cr - 1; nc = cc; }
      }
      if (nr == -1) return false;
      pr = cr; pc = cc; cr = nr; cc = nc;
    } while (!(cr == loop[0][0] && cc == loop[0][1]));
    if (v < loop.length) return false;
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++) {
        if (types[r][c] == CellType.empty) continue;
        final t = cells[r][c].first;
        if (types[r][c] == CellType.white) {
          if (!_straights.contains(t)) return false;
          final dirs = _getDirs(t);
          bool hasTurn = false;
          for (final d in dirs) {
            final nr = r + d[0], nc = c + d[1];
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && _turns.contains(cells[nr][nc].first)) { hasTurn = true; break; }
          }
          if (!hasTurn) return false;
        } else {
          if (!_turns.contains(t)) return false;
          final dirs = _getDirs(t);
          for (final d in dirs) {
            final nr = r + d[0], nc = c + d[1];
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
              final nt = cells[nr][nc].first;
              if (nt == 0 || !_straights.contains(nt)) return false;
            }
          }
        }
      }
    return true;
  }

  static List<List<int>> _getDirs(int t) {
    switch (t) {
      case 1: return [[-1, 0], [1, 0]];
      case 2: return [[0, -1], [0, 1]];
      case 3: return [[-1, 0], [0, 1]];
      case 4: return [[0, 1], [1, 0]];
      case 5: return [[1, 0], [0, -1]];
      case 6: return [[0, -1], [-1, 0]];
      default: return [];
    }
  }

  static List<List<int>> _near(int r, int c, int rows, int cols) {
    final n = <List<int>>[];
    if (r > 0) n.add([r - 1, c]);
    if (r < rows - 1) n.add([r + 1, c]);
    if (c > 0) n.add([r, c - 1]);
    if (c < cols - 1) n.add([r, c + 1]);
    return n;
  }

  static List<List<Set<int>>> _clone(List<List<Set<int>>> c, int rows, int cols) =>
      List.generate(rows, (r) => List.generate(cols, (cc) => Set<int>.from(c[r][cc])));

  static void _restore(List<List<Set<int>>> c, List<List<Set<int>>> b, int rows, int cols) {
    for (int r = 0; r < rows; r++) for (int cc = 0; cc < cols; cc++) c[r][cc] = Set<int>.from(b[r][cc]);
  }

  /// dot-to-dot 边模型：
  ///   hEdges[r][c] : dot(c,r)↔dot(c+1,r)   r=0..rows, c=0..cols-1
  ///   vEdges[r][c] : dot(c,r)↔dot(c,r+1)   r=0..rows-1, c=0..cols
  /// cell(r,c) 的四边：
  ///   上 = hEdges[r][c]   下 = hEdges[r+1][c]
  ///   左 = vEdges[r][c]   右 = vEdges[r][c+1]
  static (List<List<EdgeState>>, List<List<EdgeState>>) _toEdges(
      List<List<Set<int>>> cells, int rows, int cols) {
    final h = List.generate(rows + 1, (_) => List.filled(cols, EdgeState.none));
    final v = List.generate(rows, (_) => List.filled(cols + 1, EdgeState.none));
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++) {
        final t = cells[r][c].first;
        if (t == 0) continue;
        if (_U.contains(t)) h[r][c] = EdgeState.line;       // 上
        if (_D.contains(t)) h[r + 1][c] = EdgeState.line;   // 下
        if (_L.contains(t)) v[r][c] = EdgeState.line;       // 左
        if (_R.contains(t)) v[r][c + 1] = EdgeState.line;   // 右
      }
    return (h, v);
  }
}

// ============================================================================
//  Masyu 谜题生成器
// ============================================================================
class MasyuGenerator {
  final Random _rng;
  MasyuGenerator([int? seed]) : _rng = Random(seed);

  (MasyuPuzzle, List<List<EdgeState>>, List<List<EdgeState>>) generate({int rows = 7, int cols = 7}) {
    for (int a = 0; a < 50; a++) {
      final (h, v) = _genLoop(rows, cols);
      final cells = _placePearls(rows, cols, h, v);
      if (!_hasValidWhitePearls(cells, rows, cols, h, v)) continue;
      final puzzle = MasyuPuzzle(rows, cols, cells);
      _thinOut(puzzle, h, v);
      return (puzzle, h, v);
    }
    return _fallback(rows, cols);
  }

  // ---- 内部 / 边界边工具 ----

  /// cell(r,c) 四边：左=h[r][c] 右=h[r][c+1] 上=v[r][c] 下=v[r+1][c]
  bool _isTurn(int r, int c, int rows, int cols,
      List<List<EdgeState>> h, List<List<EdgeState>> v) {
    final left  = h[r][c] == EdgeState.line;
    final right = h[r][c + 1] == EdgeState.line;
    final top   = v[r][c] == EdgeState.line;
    final bottom = v[r + 1][c] == EdgeState.line;
    return (left ? 1 : 0) + (right ? 1 : 0) == 1 && (top ? 1 : 0) + (bottom ? 1 : 0) == 1;
  }

  bool _hasValidWhitePearls(List<List<CellType>> cells, int rows, int cols,
      List<List<EdgeState>> h, List<List<EdgeState>> v) {
    int wc = 0;
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++) {
        if (cells[r][c] != CellType.white) continue;
        wc++;
        final left  = h[r][c] == EdgeState.line;
        final right = h[r][c + 1] == EdgeState.line;
        final top   = v[r][c] == EdgeState.line;
        final bottom = v[r + 1][c] == EdgeState.line;
        bool valid = false;
        if (left && right) {
          if (c > 0 && _isTurn(r, c - 1, rows, cols, h, v)) valid = true;
          if (c < cols - 1 && _isTurn(r, c + 1, rows, cols, h, v)) valid = true;
        }
        if (top && bottom) {
          if (r > 0 && _isTurn(r - 1, c, rows, cols, h, v)) valid = true;
          if (r < rows - 1 && _isTurn(r + 1, c, rows, cols, h, v)) valid = true;
        }
        if (!valid) return false;
      }
    return wc > 0;
  }

  List<List<CellType>> _placePearls(int rows, int cols,
      List<List<EdgeState>> h, List<List<EdgeState>> v) {
    final cells = List.generate(rows, (_) => List.filled(cols, CellType.empty));
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++) {
        final left  = h[r][c] == EdgeState.line;
        final right = h[r][c + 1] == EdgeState.line;
        final top   = v[r][c] == EdgeState.line;
        final bottom = v[r + 1][c] == EdgeState.line;
        final hc = (left ? 1 : 0) + (right ? 1 : 0);
        final vc = (top ? 1 : 0) + (bottom ? 1 : 0);
        if (hc == 2 && vc == 0) cells[r][c] = CellType.white;
        else if (vc == 2 && hc == 0) cells[r][c] = CellType.white;
        else if (hc == 1 && vc == 1) cells[r][c] = CellType.black;
      }
    return cells;
  }

  void _thinOut(MasyuPuzzle puzzle,
      List<List<EdgeState>> h, List<List<EdgeState>> v) {
    final rows = puzzle.rows, cols = puzzle.cols;
    final pos = <List<int>>[];
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++)
        if (puzzle.cells[r][c] != CellType.empty) pos.add([r, c]);
    if (pos.length <= 6) return;
    pos.shuffle(_rng);
    final keep = (pos.length * 0.55).round().clamp(6, pos.length - 1);
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++)
        puzzle.cells[r][c] = CellType.empty;
    for (int i = 0; i < keep; i++) {
      final r = pos[i][0], c = pos[i][1];
      final left  = h[r][c] == EdgeState.line;
      final right = h[r][c + 1] == EdgeState.line;
      final top   = v[r][c] == EdgeState.line;
      final bottom = v[r + 1][c] == EdgeState.line;
      final hc = (left ? 1 : 0) + (right ? 1 : 0);
      final vc = (top ? 1 : 0) + (bottom ? 1 : 0);
      if (hc == 2 && vc == 0) puzzle.cells[r][c] = CellType.white;
      else if (vc == 2 && hc == 0) puzzle.cells[r][c] = CellType.white;
      else if (hc == 1 && vc == 1) puzzle.cells[r][c] = CellType.black;
    }
  }

  // ---- 外框回退 ----

  (MasyuPuzzle, List<List<EdgeState>>, List<List<EdgeState>>) _fallback(int rows, int cols) {
    final h = List.generate(rows + 1, (_) => List.filled(cols, EdgeState.none));
    final v = List.generate(rows, (_) => List.filled(cols + 1, EdgeState.none));
    for (int c = 0; c < cols; c++) { h[0][c] = EdgeState.line; h[rows][c] = EdgeState.line; }
    for (int r = 0; r < rows; r++) { v[r][0] = EdgeState.line; v[r][cols] = EdgeState.line; }
    final cells = _placePearls(rows, cols, h, v);
    return (MasyuPuzzle(rows, cols, cells), h, v);
  }

  // ---- 区域生长 ----

  (List<List<EdgeState>>, List<List<EdgeState>>) _genLoop(int rows, int cols) {
    for (int a = 0; a < 30; a++) {
      final inside = List.generate(rows, (_) => List.filled(cols, false));
      inside[_rng.nextInt(rows)][_rng.nextInt(cols)] = true;
      final q = <List<int>>[];
      for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) if (inside[r][c]) q.add([r, c]);
      final target = ((rows * cols) * (0.3 + _rng.nextDouble() * 0.4)).round().clamp(4, rows * cols - 4);
      while (_cnt(inside) < target && q.isNotEmpty) {
        q.shuffle(_rng);
        final p = q.removeLast();
        for (final nb in _nb(p[0], p[1], rows, cols))
          if (!inside[nb[0]][nb[1]] && _rng.nextDouble() < 0.4) { inside[nb[0]][nb[1]] = true; q.add([nb[0], nb[1]]); }
      }
      final cnt = _cnt(inside);
      if (cnt < 4 || cnt > rows * cols - 4) continue;
      final r = _boundary(inside, rows, cols);
      if (r != null) return r;
    }
    return _rect(rows, cols);
  }

  (List<List<EdgeState>>, List<List<EdgeState>>) _rect(int rows, int cols) {
    final h = List.generate(rows + 1, (_) => List.filled(cols, EdgeState.none));
    final v = List.generate(rows, (_) => List.filled(cols + 1, EdgeState.none));
    for (int c = 0; c < cols; c++) { h[0][c] = EdgeState.line; h[rows][c] = EdgeState.line; }
    for (int r = 0; r < rows; r++) { v[r][0] = EdgeState.line; v[r][cols] = EdgeState.line; }
    return (h, v);
  }

  int _cnt(List<List<bool>> inside) {
    int n = 0;
    for (final r in inside) for (final v in r) if (v) n++;
    return n;
  }

  List<List<int>> _nb(int r, int c, int rows, int cols) {
    final n = <List<int>>[];
    if (r > 0) n.add([r - 1, c]);
    if (r < rows - 1) n.add([r + 1, c]);
    if (c > 0) n.add([r, c - 1]);
    if (c < cols - 1) n.add([r, c + 1]);
    return n;
  }

  /// inside[][] → hEdges/vEdges (dot-to-dot)
  /// hEdges[r][c] : dot(c,r)↔dot(c+1,r)   r=0..rows, c=0..cols-1
  ///   r=0: 顶边界     → inside[0][c]
  ///   0<r<rows: 内部 → inside[r-1][c]!=inside[r][c]
  ///   r=rows: 底边界  → inside[rows-1][c]
  /// vEdges[r][c] : dot(c,r)↔dot(c,r+1)   r=0..rows-1, c=0..cols
  ///   c=0: 左边界     → inside[r][0]
  ///   0<c<cols: 内部 → inside[r][c-1]!=inside[r][c]
  ///   c=cols: 右边界  → inside[r][cols-1]
  (List<List<EdgeState>>, List<List<EdgeState>>)? _boundary(
      List<List<bool>> inside, int rows, int cols) {
    final h = List.generate(rows + 1, (_) => List.filled(cols, EdgeState.none));
    final v = List.generate(rows, (_) => List.filled(cols + 1, EdgeState.none));

    for (int r = 0; r <= rows; r++)
      for (int c = 0; c < cols; c++) {
        if (r == 0) { if (inside[0][c]) h[r][c] = EdgeState.line; }
        else if (r == rows) { if (inside[rows - 1][c]) h[r][c] = EdgeState.line; }
        else { if (inside[r - 1][c] != inside[r][c]) h[r][c] = EdgeState.line; }
      }

    for (int r = 0; r < rows; r++)
      for (int c = 0; c <= cols; c++) {
        if (c == 0) { if (inside[r][0]) v[r][c] = EdgeState.line; }
        else if (c == cols) { if (inside[r][cols - 1]) v[r][c] = EdgeState.line; }
        else { if (inside[r][c - 1] != inside[r][c]) v[r][c] = EdgeState.line; }
      }

    if (!_valid(h, v, rows, cols)) return null;
    return (h, v);
  }

  bool _valid(List<List<EdgeState>> h, List<List<EdgeState>> v, int rows, int cols) {
    final deg = <String, int>{};
    void inc(String k) { deg[k] = (deg[k] ?? 0) + 1; }
    for (int r = 0; r <= rows; r++)
      for (int c = 0; c < cols; c++)
        if (h[r][c] == EdgeState.line) { inc('$r,$c'); inc('$r,${c + 1}'); }
    for (int r = 0; r < rows; r++)
      for (int c = 0; c <= cols; c++)
        if (v[r][c] == EdgeState.line) { inc('$r,$c'); inc('${r + 1},$c'); }
    for (final d in deg.values) if (d != 0 && d != 2) return false;
    return deg.isNotEmpty;
  }
}
