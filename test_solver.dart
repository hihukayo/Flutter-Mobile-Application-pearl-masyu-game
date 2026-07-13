import 'package:puzzle_game/models/masyu_game.dart';
import 'package:puzzle_game/models/masyu_solver.dart';

void debugCells(List<List<Set<int>>> cells, int rows, int cols) {
  print('所有格子类型:');
  for (int r = 0; r < rows; r++) {
    String row = '';
    for (int c = 0; c < cols; c++) {
      row += '${cells[r][c].length} ';
    }
    print('  $row');
  }
}

void main() {
  print('=== 详细调试 ===');
  final gen = MasyuGenerator(42);
  final (puzzle, h, v) = gen.generate();
  final rows = puzzle.rows, cols = puzzle.cols;

  // 初始化求解器状态
  final cells = List.generate(rows,
      (_) => List.generate(cols, (_) => <int>{0, 1, 2, 3, 4, 5, 6}));

  // 应用珍珠约束
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (puzzle.cells[r][c] != CellType.empty) cells[r][c].remove(0);
      if (puzzle.cells[r][c] == CellType.white) cells[r][c].removeAll({3, 4, 5, 6});
      if (puzzle.cells[r][c] == CellType.black) cells[r][c].removeAll({1, 2});
    }
  }
  print('珍珠约束后:');
  debugCells(cells, rows, cols);

  // 边界约束
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (r == 0) cells[r][c].removeAll({1, 3, 6});
      if (r == rows - 1) cells[r][c].removeAll({1, 4, 5});
      if (c == 0) cells[r][c].removeAll({2, 5, 6});
      if (c == cols - 1) cells[r][c].removeAll({2, 3, 4});
    }
  }
  print('边界约束后:');
  debugCells(cells, rows, cols);

  // 检查类型数量
  int multi = 0;
  for (int r = 0; r < rows; r++)
    for (int c = 0; c < cols; c++)
      if (cells[r][c].length > 1) multi++;
  print('多类型格子数: $multi');
}
