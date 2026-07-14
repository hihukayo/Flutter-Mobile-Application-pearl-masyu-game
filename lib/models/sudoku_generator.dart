import 'dart:math';
import 'sudoku_game.dart';

class SudokuGenerator {
  final int boardSize;
  final Random _rng;
  int get gridSize => boardSize * boardSize;

  SudokuGenerator({this.boardSize = 3, int? seed})
      : _rng = Random(seed);

  SudokuPuzzle generate({int clues = 30}) {
    final puzzle = SudokuPuzzle(boardSize: boardSize);
    _fillGrid(puzzle.solution);
    // 复制答案到题目
    for (int r = 0; r < gridSize; r++)
      for (int c = 0; c < gridSize; c++)
        puzzle.cells[r][c] = puzzle.solution[r][c];
    // 移除数字
    _removeCells(puzzle, clues);
    // 标记题目格
    for (int r = 0; r < gridSize; r++)
      for (int c = 0; c < gridSize; c++)
        puzzle.given[r][c] = puzzle.cells[r][c] != 0;
    return puzzle;
  }

  bool _fillGrid(List<List<int>> grid) {
    final empty = _findEmpty(grid);
    if (empty == null) return true;
    final (r, c) = empty;
    final nums = List.generate(gridSize, (i) => i + 1)..shuffle(_rng);
    for (final n in nums) {
      if (_isValid(grid, r, c, n)) {
        grid[r][c] = n;
        if (_fillGrid(grid)) return true;
        grid[r][c] = 0;
      }
    }
    return false;
  }

  bool _isValid(List<List<int>> grid, int r, int c, int n) {
    for (int i = 0; i < gridSize; i++) {
      if (grid[r][i] == n) return false;
      if (grid[i][c] == n) return false;
    }
    final br = r - r % boardSize, bc = c - c % boardSize;
    for (int i = br; i < br + boardSize; i++)
      for (int j = bc; j < bc + boardSize; j++)
        if (grid[i][j] == n) return false;
    return true;
  }

  (int, int)? _findEmpty(List<List<int>> grid) {
    for (int r = 0; r < gridSize; r++)
      for (int c = 0; c < gridSize; c++)
        if (grid[r][c] == 0) return (r, c);
    return null;
  }

  void _removeCells(SudokuPuzzle puzzle, int clues) {
    final total = gridSize * gridSize;
    final all = <int>[];
    for (int i = 0; i < total; i++) all.add(i);
    all.shuffle(_rng);
    int target = total - clues;
    for (final pos in all) {
      if (target <= 0) break;
      final r = pos ~/ gridSize, c = pos % gridSize;
      final saved = puzzle.cells[r][c];
      puzzle.cells[r][c] = 0;
      if (boardSize == 3) {
        // 3x3: 验证唯一解
        if (_countSolutions(puzzle.clone(), 2) != 1) {
          puzzle.cells[r][c] = saved;
        } else {
          target--;
        }
      } else {
        // 4x4: 跳过唯一解验证（性能原因）
        target--;
      }
    }
  }

  int _countSolutions(SudokuPuzzle puzzle, int limit) {
    int count = 0;
    void solve(List<List<int>> grid) {
      if (count >= limit) return;
      final empty = _findEmpty(grid);
      if (empty == null) { count++; return; }
      final (r, c) = empty;
      for (int n = 1; n <= gridSize; n++) {
        if (_isValid(grid, r, c, n)) {
          grid[r][c] = n;
          solve(grid);
          grid[r][c] = 0;
          if (count >= limit) return;
        }
      }
    }
    final grid = List.generate(
        gridSize, (r) => List<int>.from(puzzle.cells[r]));
    solve(grid);
    return count;
  }
}
