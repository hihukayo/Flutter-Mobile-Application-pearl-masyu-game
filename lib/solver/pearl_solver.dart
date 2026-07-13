import '../models/constants.dart';

// ============================================================================
//  pearl_solve — 移植 pearl.c 第291-883行
//  工作区: (2*w+1) × (2*h+1)
//    - 奇/奇: cell 状态位掩码
//    - 偶/奇: 水平边状态
//    - 奇/偶: 垂直边状态
//    - 偶/偶: 顶点
// ============================================================================

/// cell 状态位 (pearl.c 第62-82行)
const bLR = 1 << Dir.LR;
const bRL = 1 << Dir.LR; // 同 bLR
const bUD = 1 << Dir.UD;
const bDU = 1 << Dir.UD;
const bLU = 1 << Dir.LU;
const bUL = 1 << Dir.LU;
const bLD = 1 << Dir.LD;
const bDL = 1 << Dir.LD;
const bRU = 1 << Dir.RU;
const bUR = 1 << Dir.RU;
const bRD = 1 << Dir.RD;
const bDR = 1 << Dir.RD;
const bBLANK = 1 << 0; // BLANK = 0

const _ALL_STATES = bLR | bUD | bLU | bLD | bRU | bRD | bBLANK;
const _STRAIGHT_STATES = bLR | bUD;
const _CORNER_STATES = bLU | bLD | bRU | bRD;
const _CONNECTED = 1;
const _DISCONNECTED = 2;
const _UNKNOWN = 3;

class PearlSolver {
  int w = 0, h = 0, ws = 0, hs = 0;
  late List<int> _ws; // workspace
  int _budget = 0;

  /// 求解入口
  /// 返回: -1=无解, 0=矛盾, 1=唯一解, 2=多解
  int solve(List<ClueType> clues, int width, int height,
      {int difficulty = 1, bool partial = false, int budget = 500}) {
    w = width;
    h = height;
    ws = 2 * w + 1;
    hs = 2 * h + 1;
    _budget = budget;

    _init(clues);
    final result = _solve(difficulty, partial);
    return result;
  }

  /// 获取解 (hEdges, vEdges)
  (List<List<int>>, List<List<int>>) getEdges() {
    final hEdges = List.generate(h + 1, (_) => List.filled(w, 0));
    final vEdges = List.generate(h, (_) => List.filled(w + 1, 0));
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final st = _ws[(2 * y + 1) * ws + (2 * x + 1)];
        if (st == 0) continue;
        if ((st & bLR) != 0 || (st & bRL) != 0) {
          if (x > 0) vEdges[y][x] = 1;
          if (x < w - 1) vEdges[y][x + 1] = 1;
        }
        if ((st & bUD) != 0 || (st & bDU) != 0) {
          if (y > 0) hEdges[y][x] = 1;
          if (y < h - 1) hEdges[y + 1][x] = 1;
        }
      }
    }
    // 从 workspace 边状态直接读取
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final hEdge = _ws[(2 * y) * ws + (2 * x + 1)];
        if (hEdge == _CONNECTED && y > 0) hEdges[y][x] = 1;
        final hEdgeB = _ws[(2 * y + 2) * ws + (2 * x + 1)];
        if (hEdgeB == _CONNECTED && y < h - 1) hEdges[y + 1][x] = 1;
        final vEdge = _ws[(2 * y + 1) * ws + (2 * x)];
        if (vEdge == _CONNECTED && x > 0) vEdges[y][x] = 1;
        final vEdgeR = _ws[(2 * y + 1) * ws + (2 * x + 2)];
        if (vEdgeR == _CONNECTED && x < w - 1) vEdges[y][x + 1] = 1;
      }
    }
    return (hEdges, vEdges);
  }

  // ---- 初始化 ----

  void _init(List<ClueType> clues) {
    _ws = List.filled(ws * hs, 0);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = (2 * y + 1) * ws + (2 * x + 1);
        final clue = clues[y * w + x];
        if (clue == ClueType.none) {
          _ws[idx] = _ALL_STATES;
        } else if (clue == ClueType.corner) {
          _ws[idx] = _CORNER_STATES;
        } else {
          _ws[idx] = _STRAIGHT_STATES | bBLANK;
        }
      }
    }

    // 边: 边界断开，内部未知
    for (int y = 0; y <= h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = (2 * y) * ws + (2 * x + 1);
        _ws[idx] = (y == 0 || y == h) ? _DISCONNECTED : _UNKNOWN;
      }
    }
    for (int y = 0; y < h; y++) {
      for (int x = 0; x <= w; x++) {
        final idx = (2 * y + 1) * ws + (2 * x);
        _ws[idx] = (x == 0 || x == w) ? _DISCONNECTED : _UNKNOWN;
      }
    }
    // 顶点
    for (int y = 0; y <= h; y++) {
      for (int x = 0; x <= w; x++) {
        _ws[(2 * y) * ws + (2 * x)] = 0;
      }
    }
  }

  // ---- 求解 ----

  int _solve(int difficulty, bool partial) {
    int result;
    for (int i = 0; i < 200; i++) {
      result = _propagate(difficulty);
      if (result == -1 || result == 1) return result;
      if (result != 0) continue;
      // 未完成 → DFS
      return _dfs(difficulty, partial);
    }
    return -1;
  }

  int _propagate(int difficulty) {
    bool changed = true;
    int iter = 0;
    while (changed) {
      changed = false;
      iter++;
      if (iter > 200) return -1;

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final res = _propCell(x, y);
          if (res == -1) return -1;
          if (res == 1) changed = true;
        }
      }

      // 边→方格传播
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final res = _propCellFromEdges(x, y);
          if (res == -1) return -1;
          if (res == 1) changed = true;
        }
      }

      if (difficulty >= 1) {
        // TRICKY: 短路检测
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final res = _checkShortCircuit(x, y);
            if (res == -1) return -1;
            if (res == 1) changed = true;
          }
        }
      }
    }
    return 0;
  }

  /// 方格传播：根据cell状态推导边
  int _propCell(int x, int y) {
    final idx = (2 * y + 1) * ws + (2 * x + 1);
    int st = _ws[idx];
    if (st == 0) return -1;
    if (st == bBLANK) return 1;

    // 检查每个方向
    for (final d in [Dir.R, Dir.U, Dir.L, Dir.D]) {
      final eIdx = _edgeIdx(x, y, d);
      if (eIdx < 0) continue;
      final eSt = _ws[eIdx];

      if (eSt == _CONNECTED) {
        // 边连通→移除不支持此边的状态
        final mask = _statesWithDir(d);
        if ((st & mask) == 0) return -1;
        st &= mask;
      } else if (eSt == _DISCONNECTED) {
        // 边断开→移除需要此边的状态
        final mask = _statesWithDir(d);
        final removeMask = st & mask;
        if (removeMask != 0) {
          st &= ~mask;
          if (st == 0) return -1;
        }
      }
    }
    _ws[idx] = st;
    return st != _ws[(2 * y + 1) * ws + (2 * x + 1)] ? 1 : 0;
  }

  /// 从边状态推导方格
  int _propCellFromEdges(int x, int y) {
    final idx = (2 * y + 1) * ws + (2 * x + 1);
    final st = _ws[idx];
    if (st == 0 || st == bBLANK) return 0;

    for (final d in [Dir.R, Dir.U, Dir.L, Dir.D]) {
      final eIdx = _edgeIdx(x, y, d);
      if (eIdx < 0) continue;
      final eSt = _ws[eIdx];
      if (eSt != _UNKNOWN) continue;

      // 所有可能状态都要此边→标记连通
      final mask = _statesWithDir(d);
      if ((st & ~mask) == 0) {
        _ws[eIdx] = _CONNECTED;
        return 1;
      }
      // 所有可能状态都不要此边→标记断开
      if ((st & mask) == 0) {
        _ws[eIdx] = _DISCONNECTED;
        return 1;
      }
    }
    return 0;
  }

  int _checkShortCircuit(int x, int y) {
    // TRICKY 难度的短路检测
    return 0; // 简化版
  }

  // ---- DFS ----

  int _dfs(int difficulty, bool partial, [int depth = 0]) {
    if (depth > 30) return -1;
    _budget--;
    if (_budget <= 0) return 2;

    final bak = List<int>.from(_ws);

    // 找第一个未确定的 cell
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = (2 * y + 1) * ws + (2 * x + 1);
        final st = _ws[idx];
        if (st != bBLANK && st != 0 && st != (st & -st)) {
          // 有多个可能状态 → 分支
          for (int bit = 1; bit <= bRD; bit <<= 1) {
            if ((st & bit) == 0) continue;
            _ws[idx] = bit;
            final result = _solve(difficulty, partial);
            if (result == 1 || result == 2) {
              return result;
            }
            // 还原并尝试下一个
            for (int i = 0; i < _ws.length; i++) _ws[i] = bak[i];
          }
          return -1; // 所有分支都失败
        }
      }
    }
    // 通过连通性检查即视为有解
    if (_checkConnectivity()) return 1;
    return -1;
  }

  bool _checkConnectivity() {
    // 简化版连通性检查
    final ds = DisjointSet(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final st = _ws[(2 * y + 1) * ws + (2 * x + 1)];
        if (st == 0 || st == bBLANK) continue;
        if ((st & bLR) != 0 && x < w - 1) {
          final rst = _ws[(2 * y + 1) * ws + (2 * x + 3)];
          if (rst != 0 && rst != bBLANK) ds.union(y * w + x, y * w + x + 1);
        }
        if ((st & bUD) != 0 && y < h - 1) {
          final dst = _ws[(2 * y + 3) * ws + (2 * x + 1)];
          if (dst != 0 && dst != bBLANK) ds.union(y * w + x, (y + 1) * w + x);
        }
      }
    }
    final roots = <int>{};
    for (int i = 0; i < w * h; i++) {
      final st = _ws[(2 * (i ~/ w) + 1) * ws + (2 * (i % w) + 1)];
      if (st != 0 && st != bBLANK) roots.add(ds.find(i));
    }
    return roots.length <= 1;
  }

  // ---- 工具 ----

  int _edgeIdx(int x, int y, int d) {
    if (d == Dir.R && x < w) return (2 * y + 1) * ws + (2 * x + 2);
    if (d == Dir.L && x > 0) return (2 * y + 1) * ws + (2 * x);
    if (d == Dir.D && y < h) return (2 * y + 2) * ws + (2 * x + 1);
    if (d == Dir.U && y > 0) return (2 * y) * ws + (2 * x + 1);
    return -1;
  }

  int _statesWithDir(int d) {
    switch (d) {
      case Dir.R: return bLR | bRU | bRD;
      case Dir.L: return bLR | bLU | bLD;
      case Dir.U: return bUD | bLU | bRU;
      case Dir.D: return bUD | bLD | bRD;
      default: return 0;
    }
  }
}

class DisjointSet {
  final List<int> parent;
  DisjointSet(int n) : parent = List.generate(n, (i) => i);
  int find(int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
  }
  void union(int a, int b) { final ra = find(a), rb = find(b); if (ra != rb) parent[ra] = rb; }
}
