class SudokuPuzzle {
  final int boardSize;    // 3 或 4
  final int gridSize;     // 9 或 16
  final List<List<int>> cells;       // 0=空, 1-9 或 1-16
  final List<List<bool>> given;      // true=题目给的（不可修改）
  final List<List<Set<int>>> notes;  // 笔记模式的小数字
  List<List<int>> solution;          // 完整答案

  SudokuPuzzle({this.boardSize = 3})
      : gridSize = boardSize * boardSize,
        cells = List.generate(
            boardSize * boardSize, (_) => List.filled(boardSize * boardSize, 0)),
        given = List.generate(
            boardSize * boardSize, (_) => List.filled(boardSize * boardSize, false)),
        notes = List.generate(
            boardSize * boardSize,
            (_) => List.generate(boardSize * boardSize, (_) => <int>{})),
        solution = List.generate(
            boardSize * boardSize, (_) => List.filled(boardSize * boardSize, 0));

  SudokuPuzzle clone() {
    final p = SudokuPuzzle(boardSize: boardSize);
    for (int r = 0; r < gridSize; r++)
      for (int c = 0; c < gridSize; c++) {
        p.cells[r][c] = cells[r][c];
        p.given[r][c] = given[r][c];
        p.notes[r][c] = Set<int>.from(notes[r][c]);
        p.solution[r][c] = solution[r][c];
      }
    return p;
  }

  void setNote(int r, int c, int n) {
    notes[r][c].clear();
    notes[r][c].add(n);
  }

  bool isComplete() {
    for (int r = 0; r < gridSize; r++)
      for (int c = 0; c < gridSize; c++)
        if (cells[r][c] == 0) return false;
    return true;
  }

  bool isCorrect() {
    for (int r = 0; r < gridSize; r++)
      for (int c = 0; c < gridSize; c++)
        if (cells[r][c] != solution[r][c]) return false;
    return true;
  }

  /// 将数值转换为显示字符：1-9 显示数字，10+ 显示 A-F
  static String displayValue(int val) {
    if (val >= 1 && val <= 9) return '$val';
    if (val >= 10 && val <= 16) return String.fromCharCode(0x41 + val - 10); // A-F
    return '';
  }
}
