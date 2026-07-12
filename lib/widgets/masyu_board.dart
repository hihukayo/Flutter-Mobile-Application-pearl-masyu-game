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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final p = widget.puzzle;
        // 节点间距
        final spacing = size / (p.cols + 1);
        // 棋盘实际占宽
        final boardSize = spacing * (p.cols + 1);
        final offsetX = (constraints.maxWidth - boardSize) / 2;
        final offsetY = (constraints.maxHeight - boardSize) / 2;

        return GestureDetector(
          onTapDown: (details) {
            final pos = details.localPosition;
            // 转为相对于棋盘左上角的坐标
            final bx = pos.dx - offsetX;
            final by = pos.dy - offsetY;
            // 计算最近的网格节点索引
            final col = (bx / spacing).round();
            final row = (by / spacing).round();

            // 点击在两个节点之间的区域 => 画线
            // 检查点击是否靠近某条水平或垂直边
            final nodeX = col * spacing;
            final nodeY = row * spacing;
            final dx = bx - nodeX;
            final dy = by - nodeY;

            // 边的判定阈值
            final threshold = spacing * 0.2;

            setState(() {
              // 水平边：点击在水平方向靠近中点，垂直方向在节点附近
              if (dy.abs() < threshold && dx.abs() < spacing * 0.6) {
                final c = (bx / spacing).floor();
                final r = row;
                if (r >= 0 && r < p.rows && c >= 0 && c < p.cols - 1) {
                  p.hEdges[r][c] = _nextEdge(p.hEdges[r][c]);
                }
              }
              // 垂直边
              if (dx.abs() < threshold && dy.abs() < spacing * 0.6) {
                final r = (by / spacing).floor();
                final c = col;
                if (r >= 0 && r < p.rows - 1 && c >= 0 && c < p.cols) {
                  p.vEdges[r][c] = _nextEdge(p.vEdges[r][c]);
                }
              }
            });
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _MasyuPainter(
              puzzle: widget.puzzle,
              spacing: spacing,
              offsetX: offsetX,
              offsetY: offsetY,
            ),
          ),
        );
      },
    );
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
  final double spacing;
  final double offsetX;
  final double offsetY;

  _MasyuPainter({
    required this.puzzle,
    required this.spacing,
    required this.offsetX,
    required this.offsetY,
  });

  Offset _node(int col, int row) {
    return Offset(offsetX + (col + 1) * spacing, offsetY + (row + 1) * spacing);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = puzzle.rows;
    final cols = puzzle.cols;

    // ---- 1. 绘制节点（小灰点） ----
    final dotPaint = Paint()..color = const Color(0xFFBBBBBB);
    for (int r = 0; r <= rows; r++) {
      for (int c = 0; c <= cols; c++) {
        canvas.drawCircle(_node(c, r), 2.5, dotPaint);
      }
    }

    // ---- 2. 绘制玩家画的线 ----
    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // 水平边
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 1; c++) {
        if (puzzle.hEdges[r][c] == EdgeState.line) {
          final p1 = _node(c + 1, r);
          final p2 = _node(c + 2, r);
          canvas.drawLine(
            Offset((p1.dx + p2.dx) / 2, p1.dy),
            Offset((p1.dx + p2.dx) / 2, p1.dy),
            linePaint,
          );
          canvas.drawLine(p1, p2, linePaint);
        }
        if (puzzle.hEdges[r][c] == EdgeState.cross) {
          final p = _node(c + 1, r);
          final s = 6.0;
          canvas.drawLine(Offset(p.dx - s, p.dy - s), Offset(p.dx + s, p.dy + s),
              Paint()..color = Colors.red[300]!..strokeWidth = 2);
          canvas.drawLine(Offset(p.dx + s, p.dy - s), Offset(p.dx - s, p.dy + s),
              Paint()..color = Colors.red[300]!..strokeWidth = 2);
        }
      }
    }

    // 垂直边
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols; c++) {
        if (puzzle.vEdges[r][c] == EdgeState.line) {
          final p1 = _node(c, r + 1);
          final p2 = _node(c, r + 2);
          canvas.drawLine(p1, p2, linePaint);
        }
        if (puzzle.vEdges[r][c] == EdgeState.cross) {
          final p = _node(c, r + 1);
          final s = 6.0;
          canvas.drawLine(Offset(p.dx - s, p.dy - s), Offset(p.dx + s, p.dy + s),
              Paint()..color = Colors.red[300]!..strokeWidth = 2);
          canvas.drawLine(Offset(p.dx + s, p.dy - s), Offset(p.dx - s, p.dy + s),
              Paint()..color = Colors.red[300]!..strokeWidth = 2);
        }
      }
    }

    // ---- 3. 绘制珍珠 ----
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (puzzle.cells[r][c] == CellType.empty) continue;

        final center = _node(c, r);
        final radius = spacing * 0.38;

        if (puzzle.cells[r][c] == CellType.white) {
          // 白珍珠：白色填充 + 粗黑边框
          canvas.drawCircle(center, radius, Paint()..color = Colors.white);
          canvas.drawCircle(center, radius, Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
        } else {
          // 黑珍珠：纯黑填充
          canvas.drawCircle(center, radius, Paint()..color = Colors.black87);
          // 细白边增加精致感
          canvas.drawCircle(center, radius, Paint()
            ..color = Colors.black87
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
