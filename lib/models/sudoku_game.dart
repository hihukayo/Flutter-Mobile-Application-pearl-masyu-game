class SudokuPuzzle {
  final int size = 9;
  final List<List<int>> cells;       // 0=空, 1-9=数字
  final List<List<bool>> given;      // true=题目给的（不可修改）
  final List<List<Set<int>>> notes;  // 笔记模式的小数字
  List<List<int>> solution;          // 完整答案

  SudokuPuzzle()
      : cells = List.generate(9, (_) => List.filled(9, 0)),
        given = List.generate(9, (_) => List.filled(9, false)),
        notes = List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        solution = List.generate(9, (_) => List.filled(9, 0));

  SudokuPuzzle clone() {
    final p = SudokuPuzzle();
    for (int r = 0; r < 9; r++)
      for (int c = 0; c < 9; c++) {
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
    for (int r = 0; r < 9; r++)
      for (int c = 0; c < 9; c++)
        if (cells[r][c] == 0) return false;
    return true;
  }

  bool isCorrect() {
    for (int r = 0; r < 9; r++)
      for (int c = 0; c < 9; c++)
        if (cells[r][c] != solution[r][c]) return false;
    return true;
  }
}
