import 'package:flutter/material.dart';
import '../models/masyu_game.dart';
import '../widgets/masyu_board.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late MasyuPuzzle _puzzle;
  MasyuPuzzle? _initialState;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    setState(() {
      _puzzle = MasyuPuzzle.sample();
      _initialState = MasyuPuzzle.sample();
      _initialState!.reset();
    });
  }

  void _restart() {
    setState(() {
      _puzzle.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolButton(Icons.refresh, '新游戏', _newGame),
              _toolButton(Icons.replay, '重新开始', _restart),
              _toolButton(Icons.auto_fix_high, '自动求解', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('自动求解功能待实现')),
                );
              }),
            ],
          ),
        ),
        // 棋盘
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: MasyuBoard(puzzle: _puzzle),
          ),
        ),
      ],
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: Colors.deepPurple),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.deepPurple)),
            ],
          ),
        ),
      ),
    );
  }
}
