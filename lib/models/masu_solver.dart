// ============================================================================
//  Masyu 刚性求解器 — 约束传播 + DFS 回溯
//  输入：clues矩阵 (rows×cols) 0=空, 1=白, 2=黑
// ============================================================================

const _UNK = 0;
const _FIL = 1;
const _EMP = 2;

enum SolverResult { solved, noSolution, multipleSolution }

class MasyuSolver {
  int rows = 0, cols = 0;
  List<List<int>> _h = []; // 水平边 (rows+1)×cols
  List<List<int>> _v = []; // 垂直边 rows×(cols+1)
  List<List<int>>? _clues;

  SolverResult solve(List<List<int>> clues, int boardRows, int boardCols, {int budget = 500}) {
    rows = boardRows;
    cols = boardCols;
    _clues = clues;

    final hRows = rows + 1, hCols = cols;
    final vRows = rows, vCols = cols + 1;
    _h = List.generate(hRows, (_) => List.filled(hCols, _UNK));
    _v = List.generate(vRows, (_) => List.filled(vCols, _UNK));

    int propResult = _propagate();
    if (propResult == -1) return SolverResult.noSolution;
    if (propResult == 1) return SolverResult.solved;

    // DFS
    int budget2 = budget;
    final solutions = <int>[];
    _dfs(solutions, 2, budget2);
    if (solutions.isEmpty) return SolverResult.noSolution;
    if (solutions.length == 1) return SolverResult.solved;
    return SolverResult.multipleSolution;
  }

  // ================================================================
  //  约束传播
  // ================================================================

  int _propagate() {
    bool changed = true;
    int iter = 0;
    while (changed) {
      changed = false;
      iter++;
      if (iter > 200) return -1;

      for (int r = -1; r <= rows; r++)
        for (int c = -1; c <= cols; c++) {
          final res = _propVertex(r, c);
          if (res == -1) return -1;
          if (res == 1) changed = true;
        }

      for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++) {
          if (_clues != null && _clues![r][c] == 1) {
            if (_propWhite(r, c) == -1) return -1;
          } else if (_clues != null && _clues![r][c] == 2) {
            if (_propBlack(r, c) == -1) return -1;
          }
        }

      if (_checkLoops() == -1) return -1;
    }
    if (_allSolved()) return 1;
    return 0;
  }

  int _propVertex(int r, int c) {
    final edges = <(int, bool, int, int)>[];
    if (c >= 0 && c < cols && r >= 0 && r <= rows) edges.add((_h[r][c], true, r, c));
    if (c - 1 >= 0 && c - 1 < cols && r >= 0 && r <= rows) edges.add((_h[r][c - 1], true, r, c - 1));
    if (r >= 0 && r < rows && c >= 0 && c <= cols) edges.add((_v[r][c], false, r, c));
    if (r - 1 >= 0 && r - 1 < rows && c >= 0 && c <= cols) edges.add((_v[r - 1][c], false, r - 1, c));

    int filled = 0, unknown = 0;
    for (final e in edges) {
      if (e.$1 == _FIL) filled++;
      if (e.$1 == _UNK) unknown++;
    }
    if (filled > 2) return -1;
    if (filled == 2 && unknown > 0) {
      for (final e in edges) if (e.$1 == _UNK) _set(e.$2, e.$3, e.$4, _EMP);
      return 1;
    }
    if (filled == 1 && unknown == 1) {
      for (final e in edges) if (e.$1 == _UNK) _set(e.$2, e.$3, e.$4, _FIL);
      return 1;
    }
    if (filled == 0 && unknown == 1) {
      for (final e in edges) if (e.$1 == _UNK) _set(e.$2, e.$3, e.$4, _EMP);
      return 1;
    }
    return 0;
  }

  int _propWhite(int r, int c) {
    final top = _h[r][c], bot = _h[r + 1][c], left = _v[r][c], right = _v[r][c + 1];
    if (top == _FIL && bot == _FIL) return -1;
    if (left == _FIL && right == _FIL) return -1;
    if ((top == _FIL || bot == _FIL) && (left == _FIL || right == _FIL)) return 1;
    if (top == _FIL && bot == _UNK) { _set(true, r + 1, c, _EMP); return 1; }
    if (bot == _FIL && top == _UNK) { _set(true, r, c, _EMP); return 1; }
    if (left == _FIL && right == _UNK) { _set(false, r, c + 1, _EMP); return 1; }
    if (right == _FIL && left == _UNK) { _set(false, r, c, _EMP); return 1; }
    return 0;
  }

  int _propBlack(int r, int c) {
    final top = _h[r][c], bot = _h[r + 1][c], left = _v[r][c], right = _v[r][c + 1];
    if ((top == _FIL || bot == _FIL) && (left == _FIL || right == _FIL)) return -1;
    if (top == _FIL && bot == _FIL) return 1;
    if (left == _FIL && right == _FIL) return 1;
    if (top == _FIL) { if (bot == _UNK) _set(true, r + 1, c, _FIL); if (left == _UNK) _set(false, r, c, _EMP); if (right == _UNK) _set(false, r, c + 1, _EMP); return 1; }
    if (bot == _FIL) { if (top == _UNK) _set(true, r, c, _FIL); if (left == _UNK) _set(false, r, c, _EMP); if (right == _UNK) _set(false, r, c + 1, _EMP); return 1; }
    if (left == _FIL) { if (right == _UNK) _set(false, r, c + 1, _FIL); if (top == _UNK) _set(true, r, c, _EMP); if (bot == _UNK) _set(true, r + 1, c, _EMP); return 1; }
    if (right == _FIL) { if (left == _UNK) _set(false, r, c, _FIL); if (top == _UNK) _set(true, r, c, _EMP); if (bot == _UNK) _set(true, r + 1, c, _EMP); return 1; }
    return 0;
  }

  int _checkLoops() {
    final parent = <String, String>{};
    final loops = <String>{};
    String find(String x) { while (parent[x] != x) { parent[x] = parent[parent[x]]!; x = parent[x]!; } return x; }
    void union(String a, String b) { final ra = find(a), rb = find(b); if (ra == rb) loops.add(ra); else parent[ra] = rb; }

    for (int r = 0; r <= rows; r++) for (int c = 0; c < cols; c++)
      if (_h[r][c] == _FIL) { parent.putIfAbsent('$r,$c', () => '$r,$c'); parent.putIfAbsent('$r,${c + 1}', () => '$r,${c + 1}'); union('$r,$c', '$r,${c + 1}'); }
    for (int r = 0; r < rows; r++) for (int c = 0; c <= cols; c++)
      if (_v[r][c] == _FIL) { parent.putIfAbsent('$r,$c', () => '$r,$c'); parent.putIfAbsent('${r + 1},$c', () => '${r + 1},$c'); union('$r,$c', '${r + 1},$c'); }

    if (loops.isEmpty) return 0;
    final clueVerts = <String>{};
    if (_clues != null) for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++)
      if (_clues![r][c] != 0) { clueVerts.add('$r,$c'); clueVerts.add('$r,${c + 1}'); clueVerts.add('${r + 1},$c'); clueVerts.add('${r + 1},${c + 1}'); }

    for (final root in loops) {
      final comp = <String>{};
      for (final k in parent.keys) if (find(k) == root) comp.add(k);
      if (!clueVerts.every((v) => comp.contains(v))) return -1;
    }
    return 0;
  }

  bool _allSolved() {
    for (int r = 0; r <= rows; r++) for (int c = 0; c < cols; c++) if (_h[r][c] == _UNK) return false;
    for (int r = 0; r < rows; r++) for (int c = 0; c <= cols; c++) if (_v[r][c] == _UNK) return false;
    return true;
  }

  void _set(bool isH, int r, int c, int val) {
    if (isH) { if (r >= 0 && r <= rows && c >= 0 && c < cols) _h[r][c] = val; }
    else { if (r >= 0 && r < rows && c >= 0 && c <= cols) _v[r][c] = val; }
  }

  // ================================================================
  //  DFS
  // ================================================================

  void _dfs(List<int> solutions, int limit, int budget, [int depth = 0]) {
    if (solutions.length >= limit) return;
    if (depth > 50) return;
    if (budget <= 0) { solutions.add(2); return; }
    budget--;

    final bakH = _h.map((r) => List<int>.from(r)).toList();
    final bakV = _v.map((r) => List<int>.from(r)).toList();

    final propResult = _propagate();
    if (propResult == -1) { _restore(bakH, bakV); return; }
    if (propResult == 1) { solutions.add(1); _restore(bakH, bakV); return; }

    for (int r = 0; r <= rows; r++) for (int c = 0; c < cols; c++)
      if (_h[r][c] == _UNK) {
        _h[r][c] = _FIL; _dfs(solutions, limit, budget, depth + 1); if (solutions.length >= limit) { _restore(bakH, bakV); return; }
        _h[r][c] = _EMP; _dfs(solutions, limit, budget, depth + 1); if (solutions.length >= limit) { _restore(bakH, bakV); return; }
      }
    for (int r = 0; r < rows; r++) for (int c = 0; c <= cols; c++)
      if (_v[r][c] == _UNK) {
        _v[r][c] = _FIL; _dfs(solutions, limit, budget, depth + 1); if (solutions.length >= limit) { _restore(bakH, bakV); return; }
        _v[r][c] = _EMP; _dfs(solutions, limit, budget, depth + 1); if (solutions.length >= limit) { _restore(bakH, bakV); return; }
      }

    _restore(bakH, bakV);
  }

  void _restore(List<List<int>> h, List<List<int>> v) {
    _h = h.map((r) => List<int>.from(r)).toList();
    _v = v.map((r) => List<int>.from(r)).toList();
  }

  (List<List<int>>, List<List<int>>) getSolution() {
    final h = List.generate(rows + 1, (r) => List.filled(cols, 0));
    final v = List.generate(rows, (r) => List.filled(cols + 1, 0));
    for (int r = 0; r <= rows; r++) for (int c = 0; c < cols; c++) h[r][c] = _h[r][c] == _FIL ? 1 : 0;
    for (int r = 0; r < rows; r++) for (int c = 0; c <= cols; c++) v[r][c] = _v[r][c] == _FIL ? 1 : 0;
    return (h, v);
  }
}
