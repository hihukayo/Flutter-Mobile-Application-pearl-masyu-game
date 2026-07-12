enum CellType { empty, white, black }

enum EdgeState { none, line, cross }

class MasyuPuzzle {
  final int rows;
  final int cols;
  final List<List<CellType>> cells;
  List<List<EdgeState>> hEdges; // horizontal edges (rows x (cols-1))
  List<List<EdgeState>> vEdges; // vertical edges ((rows-1) x cols)

  MasyuPuzzle(this.rows, this.cols, this.cells)
      : hEdges = [],
        vEdges = [] {
    _initEdges();
  }

  void _initEdges() {
    hEdges = List.generate(rows, (_) => List.filled(cols - 1, EdgeState.none));
    vEdges = List.generate(rows - 1, (_) => List.filled(cols, EdgeState.none));
  }

  void reset() {
    hEdges = List.generate(rows, (_) => List.filled(cols - 1, EdgeState.none));
    vEdges = List.generate(rows - 1, (_) => List.filled(cols, EdgeState.none));
  }

  /// 获取预设 7x7 题目
  static MasyuPuzzle sample() {
    final cells = List.generate(7, (_) => List.filled(7, CellType.empty));
    cells[0][2] = CellType.black;
    cells[0][4] = CellType.white;
    cells[1][5] = CellType.black;
    cells[2][0] = CellType.white;
    cells[2][3] = CellType.black;
    cells[3][1] = CellType.white;
    cells[3][5] = CellType.white;
    cells[4][3] = CellType.black;
    cells[4][6] = CellType.white;
    cells[5][1] = CellType.black;
    cells[5][5] = CellType.black;
    cells[6][2] = CellType.white;
    cells[6][4] = CellType.black;
    return MasyuPuzzle(7, 7, cells);
  }
}
