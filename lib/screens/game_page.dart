import 'dart:async';
import 'package:flutter/material.dart';
import '../models/masyu_game.dart';
import '../models/masyu_solver.dart';
import '../widgets/masyu_board.dart';

const _blue = Color(0xFF0B4CFF);

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late MasyuPuzzle _puzzle;
  late List<List<EdgeState>> _solutionH;
  late List<List<EdgeState>> _solutionV;
  int _seconds = 0;
  bool _paused = false;
  bool _isSolved = false;
  bool _hasGivenUp = false;
  bool _solutionReady = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _puzzle = MasyuPuzzle(7, 7, List.generate(7, (_) => List.filled(7, CellType.empty)));
    _solutionH = List.generate(8, (_) => List.filled(7, EdgeState.none));
    _solutionV = List.generate(7, (_) => List.filled(8, EdgeState.none));
    _startTimer();
    Future.microtask(() => _generatePuzzle());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generatePuzzle() {
    final gen = MasyuGenerator();
    final result = gen.generate();
    _puzzle = result.$1;
    _solutionH = result.$2;
    _solutionV = result.$3;
    _isSolved = false;
    _hasGivenUp = false;
    _solutionReady = true;
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _paused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_paused) setState(() => _seconds++);
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  void _newGame() {
    _timer?.cancel();
    setState(() {
      _generatePuzzle();
      _seconds = 0;
      _startTimer();
    });
  }

  void _restart() {
    setState(() {
      _puzzle.reset();
      _seconds = 0;
      _hasGivenUp = false;
      _isSolved = false;
      _startTimer();
    });
  }

  void _checkCompletion() {
    _timer?.cancel();
    if (!_solutionReady) {
      _showMsg('正在求解，请稍候...');
      _startTimer();
      return;
    }
    bool correct = true;
    for (int r = 0; r <= _puzzle.rows && correct; r++) {
      for (int c = 0; c < _puzzle.cols && correct; c++) {
        if (_puzzle.hEdges[r][c] != _solutionH[r][c]) correct = false;
      }
    }
    if (correct) {
      for (int r = 0; r < _puzzle.rows && correct; r++) {
        for (int c = 0; c <= _puzzle.cols && correct; c++) {
          if (_puzzle.vEdges[r][c] != _solutionV[r][c]) correct = false;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      if (correct) {
        _isSolved = true;
        _showMsg('恭喜你，解答正确！');
      } else {
        _showMsg('解答不正确，再试试吧');
        _startTimer();
      }
    });
  }

  void _autoSolve() {
    _timer?.cancel();
    if (!_solutionReady) {
      _showMsg('正在求解，请稍候...');
      return;
    }
    setState(() {
      _hasGivenUp = true;
      for (int r = 0; r <= _puzzle.rows; r++) {
        for (int c = 0; c < _puzzle.cols; c++) {
          _puzzle.hEdges[r][c] = _solutionH[r][c];
        }
      }
      for (int r = 0; r < _puzzle.rows; r++) {
        for (int c = 0; c <= _puzzle.cols; c++) {
          _puzzle.vEdges[r][c] = _solutionV[r][c];
        }
      }
      _showMsg('已显示参考答案（本题已作废）');
    });
  }

  String _formatTime(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Masyu', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '珍珠棋 · 画一条闭环穿过所有珍珠',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
            Text(
              _formatTime(_seconds),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: _blue, letterSpacing: 4),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  // 棋盘实际绘制高度 ≈ w * 0.9，留一点边界余量
                  return SizedBox(
                    height: w * 0.88 + 12,
                    child: MasyuBoard(puzzle: _puzzle),
                  );
                },
              ),
            ),
            // 完成按钮
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 280, height: 42,
                child: ElevatedButton(
                  onPressed: (_isSolved || _hasGivenUp) ? null : _checkCompletion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSolved ? Colors.green : _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _hasGivenUp ? Colors.grey[400] : Colors.green[200],
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isSolved ? '已完成 ✓' : (_hasGivenUp ? '已放弃' : '完成'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            // 完成与下方按钮等距
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: 280,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _iconBtn(Icons.undo_rounded, '撤销'),
                        _iconBtn(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, _paused ? '继续' : '暂停', onTap: _togglePause),
                        _iconBtn(Icons.redo_rounded, '重做'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: SizedBox(
                    width: 280,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                    _iconBtn(Icons.refresh_rounded, '新随机', onTap: _newGame),
                    _iconBtn(Icons.replay_rounded, '重来', onTap: _restart),
                    _iconBtn(Icons.auto_fix_high_rounded, '求解', onTap: (_isSolved || _hasGivenUp) ? null : _autoSolve),
                  ],
                ),
              ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: const Color(0xFF455A64)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF455A64))),
            ],
          ),
        ),
      ),
    );
  }
}
