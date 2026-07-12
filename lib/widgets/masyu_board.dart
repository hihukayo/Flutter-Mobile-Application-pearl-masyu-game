import 'package:flutter/material.dart';
import '../models/masyu_game.dart';

class MasyuBoard extends StatefulWidget {
  final MasyuPuzzle puzzle;
  const MasyuBoard({super.key, required this.puzzle});

  @override
  State<MasyuBoard> createState() => _MasyuBoardState();
}

class _MasyuBoardState extends State<MasyuBoard> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final cellSize = size / (widget.puzzle.cols + 1);
          return GestureDetector(
            onTapDown: (details) => _onTap(details.localPosition, cellSize),
            child: CustomPaint(
              size: Size(size, size),
              painter: _MasyuPainter(puzzle: widget.puzzle, cellSize: cellSize),
            ),
          );
        },
      ),
    );
  }

  void _onTap(Offset pos, double cellSize) {
    final p = widget.puzzle;
    final margin = cellSize;
    final col = ((pos.dx - margin) / cellSize).round();
    final row = ((pos.dy - margin) / cellSize).round();

    // 点击网格线（两个单元格之间的边）
    // 水平边：在行上方
    // 垂直边：在列左方
    // 点击位置在单元格中心附近 => 判断最近的边
    final cx = margin + col * cellSize;
    final cy = margin + row * cellSize;
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;

    setState(() {
      // 水平边：在两个单元格之间，dy 接近 0 且 dx 在范围内
      if (dy.abs() < cellSize * 0.3 && dx.abs() < cellSize * 0.8) {
        final r = row;
        final c = (pos.dx - margin + cellSize / 2) ~/ cellSize - 1;
        if (r >= 0 && r < p.rows && c >= 0 && c < p.cols - 1) {
          p.hEdges[r][c] = _nextEdge(p.hEdges[r][c]);
        }
      }
      // 垂直边
      if (dx.abs() < cellSize * 0.3 && dy.abs() < cellSize * 0.8) {
        final r = (pos.dy - margin + cellSize / 2) ~/ cellSize - 1;
        final c = col;
        if (r >= 0 && r < p.rows - 1 && c >= 0 && c < p.cols) {
          p.vEdges[r][c] = _nextEdge(p.vEdges[r][c]);
        }
      }
    });
  }

  EdgeState _nextEdge(EdgeState s) {
    switch (s) {
      case EdgeState.none: return EdgeState.line;
      case EdgeState.line: return EdgeState.cross;
      case EdgeState.cross: return EdgeState.none;
    }
  }
}

class _MasyuPainter extends CustomPainter {
  final MasyuPuzzle puzzle;
  final double cellSize;

  _MasyuPainter({required this.puzzle, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final margin = cellSize;
    final rows = puzzle.rows;
    final cols = puzzle.cols;

    // 背景
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFF5F0E8));

    // 绘制网格线（浅灰色）
    final gridPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1;

    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(
        Offset(margin, margin + r * cellSize),
        Offset(margin + cols * cellSize, margin + r * cellSize),
        gridPaint,
      );
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(
        Offset(margin + c * cellSize, margin),
        Offset(margin + c * cellSize, margin + rows * cellSize),
        gridPaint,
      );
    }

    // 绘制玩家画的线
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 1; c++) {
        if (puzzle.hEdges[r][c] == EdgeState.line) {
          final x1 = margin + (c + 1) * cellSize;
          final y = margin + (r + 0.5) * cellSize;
          canvas.drawLine(Offset(x1 - cellSize * 0.4, y), Offset(x1 + cellSize * 0.4, y),
              Paint()..color = Colors.black87..strokeWidth = 3..strokeCap = StrokeCap.round);
        }
      }
    }
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols; c++) {
        if (puzzle.vEdges[r][c] == EdgeState.line) {
          final x = margin + (c + 0.5) * cellSize;
          final y1 = margin + (r + 1) * cellSize;
          canvas.drawLine(Offset(x, y1 - cellSize * 0.4), Offset(x, y1 + cellSize * 0.4),
              Paint()..color = Colors.black87..strokeWidth = 3..strokeCap = StrokeCap.round);
        }
      }
    }

    // 绘制珍珠（黑白圆圈）
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (puzzle.cells[r][c] == CellType.empty) continue;

        final cx = margin + (c + 0.5) * cellSize;
        final cy = margin + (r + 0.5) * cellSize;
        final radius = cellSize * 0.35;

        if (puzzle.cells[r][c] == CellType.white) {
          // 白珍珠：白色填充 + 黑色边框
          canvas.drawCircle(Offset(cx, cy), radius,
              Paint()..color = Colors.white);
          canvas.drawCircle(Offset(cx, cy), radius,
              Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
        } else {
          // 黑珍珠：黑色填充
          canvas.drawCircle(Offset(cx, cy), radius,
              Paint()..color = Colors.black87);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
