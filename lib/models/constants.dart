// ============================================================================
//  Masyu 常量与方向宏 — 移植 pearl.c
// ============================================================================

/// 方向位掩码 (pearl.c 第55-57行)
class Dir {
  static const int R = 1;
  static const int U = 2;
  static const int L = 4;
  static const int D = 8;

  static const int LR = 5;   // L|R
  static const int UD = 10;  // U|D
  static const int LU = 6;   // L|U
  static const int LD = 12;  // L|D
  static const int RU = 3;   // R|U
  static const int RD = 9;   // R|D

  static int dx(int d) => (d == R ? 1 : 0) - (d == L ? 1 : 0);
  static int dy(int d) => (d == D ? 1 : 0) - (d == U ? 1 : 0);

  /// F(d): 翻转方向 (pearl.c 第58行)
  /// ((d << 2) | (d >> 2)) & 0xF
  static int flip(int d) => ((d << 2) | (d >> 2)) & 0xF;

  /// C(d): 顺时针旋转 (pearl.c 第59行)
  static int cw(int d) => ((d << 3) | (d >> 1)) & 0xF;

  /// A(d): 逆时针旋转 (pearl.c 第60行)
  static int ccw(int d) => ((d << 1) | (d >> 3)) & 0xF;

  static bool isLR(int t) => t == LR;
  static bool isUD(int t) => t == UD;
  static bool isStraight(int t) => t == LR || t == UD;
  static bool isTurn(int t) => t == LU || t == LD || t == RU || t == RD;
  static bool isCorner(int t) => isTurn(t);
}

/// 线索类型 (pearl.c NOCLUE=0, CORNER=1, STRAIGHT=2)
enum ClueType { none, corner, straight }

/// 边状态 (pearl.c BLANK=0, UNKNOWN=15)
enum EdgeState { blank, unknown, filled, empty }

/// 难度
enum Difficulty { easy, tricky }
