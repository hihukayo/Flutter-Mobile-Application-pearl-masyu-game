import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sudoku_game.dart';

class SudokuBoard extends StatefulWidget {
  final SudokuPuzzle puzzle;
  final bool noteMode;
  final bool readOnly;
  final void Function(int r, int c, int oldVal, int newVal)? onCellChanged;
  final VoidCallback? onRefresh;

  const SudokuBoard({
    super.key,
    required this.puzzle,
    this.noteMode = false,
    this.readOnly = false,
    this.onCellChanged,
    this.onRefresh,
  });

  @override
  State<SudokuBoard> createState() => SudokuBoardState();
}

class SudokuBoardState extends State<SudokuBoard> {
  int? _selectedRow, _selectedCol;
  final Set<String> _errors = {};
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isValidAt(int r, int c) {
    final n = widget.puzzle.cells[r][c];
    if (n == 0) return true;
    for (int i = 0; i < 9; i++) {
      if (i != c && widget.puzzle.cells[r][i] == n) return false;
      if (i != r && widget.puzzle.cells[i][c] == n) return false;
    }
    final br = r - r % 3, bc = c - c % 3;
    for (int i = br; i < br + 3; i++)
      for (int j = bc; j < bc + 3; j++)
        if ((i != r || j != c) && widget.puzzle.cells[i][j] == n) return false;
    return true;
  }

  void eraseSelected() {
    if (_selectedRow == null || _selectedCol == null) return;
    final r = _selectedRow!, c = _selectedCol!;
    if (widget.puzzle.given[r][c]) return;
    setState(() {
      widget.puzzle.cells[r][c] = 0;
      widget.puzzle.notes[r][c].clear();
      _errors.remove('$r,$c');
    });
    widget.onRefresh?.call();
  }

  void _onCellTap(int r, int c) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
    if (!widget.readOnly) {
      _textController.clear();
      _focusNode.requestFocus();
    }
  }

  void _onTextChanged(String v) {
    if (widget.readOnly) return;
    if (_selectedRow == null || _selectedCol == null) return;
    final r = _selectedRow!, c = _selectedCol!;
    if (widget.puzzle.given[r][c]) return;

    final digits = v.replaceAll(RegExp(r'[^1-9]'), '');
    if (digits.isEmpty) return;
    final n = int.parse(digits.substring(digits.length - 1));
    _textController.clear();

    if (widget.noteMode) {
      // 笔记模式：填入/替换单个笔记
      if (widget.puzzle.notes[r][c].contains(n)) {
        setState(() => widget.puzzle.notes[r][c].remove(n));
      } else {
        setState(() => widget.puzzle.setNote(r, c, n));
      }
    } else {
      // 正常模式：填入数字
      final old = widget.puzzle.cells[r][c];
      setState(() {
        widget.puzzle.cells[r][c] = n;
        widget.puzzle.notes[r][c].clear();
        _errors.remove('$r,$c');
        if (!_isValidAt(r, c)) _errors.add('$r,$c');
      });
      widget.onCellChanged?.call(r, c, old, n);
    }
    widget.onRefresh?.call();
  }

  Widget _buildNotes(int r, int c, TextStyle ts) {
    if (widget.puzzle.notes[r][c].isEmpty) return const SizedBox.shrink();
    final n = widget.puzzle.notes[r][c].first;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('$n', style: ts.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0B4CFF),
        )),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.montserrat();

    return Stack(
      children: [
        // 隐藏的 TextField（接收键盘输入）
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 0,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [],
              onChanged: _onTextChanged,
              autofocus: false,
            ),
          ),
        ),
        // 棋盘
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF455A64), width: 2.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 81,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9, mainAxisSpacing: 0, crossAxisSpacing: 0,
              ),
              itemBuilder: (_, index) {
                final r = index ~/ 9, c = index % 9;
                final val = widget.puzzle.cells[r][c];
                final isGiven = widget.puzzle.given[r][c];
                final isSelected = _selectedRow == r && _selectedCol == c;
                final isError = _errors.contains('$r,$c');
                final isSameNum = val != 0 && _selectedRow != null &&
                    _selectedCol != null && _selectedRow != r &&
                    _selectedCol != c &&
                    widget.puzzle.cells[_selectedRow!][_selectedCol!] == val;
                final inSameRow = _selectedRow == r;
                final inSameCol = _selectedCol == c;
                final inSameBox = _selectedRow != null && _selectedCol != null &&
                    r ~/ 3 == _selectedRow! ~/ 3 && c ~/ 3 == _selectedCol! ~/ 3;
                final isHighlighted = (inSameRow || inSameCol || inSameBox) && !isSelected;

                Color? textColor;
                FontWeight fontWeight;
                if (isGiven) {
                  textColor = const Color(0xFF1A1A2E);
                  fontWeight = FontWeight.w700;
                } else if (val == 0) {
                  textColor = null;
                  fontWeight = FontWeight.normal;
                } else if (isError) {
                  textColor = Colors.red[600];
                  fontWeight = FontWeight.w600;
                } else {
                  textColor = Colors.green[700];
                  fontWeight = FontWeight.w600;
                }

                return GestureDetector(
                  onTap: () => _onCellTap(r, c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFBBDEFB)
                           : isHighlighted ? const Color(0xFFF0F4F8)
                           : Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: (c + 1) % 3 == 0 ? const Color(0xFF455A64) : Colors.grey[300]!,
                          width: (c + 1) % 3 == 0 ? 2 : 0.5,
                        ),
                        bottom: BorderSide(
                          color: (r + 1) % 3 == 0 ? const Color(0xFF455A64) : Colors.grey[300]!,
                          width: (r + 1) % 3 == 0 ? 2 : 0.5,
                        ),
                      ),
                    ),
                    child: val != 0
                        ? Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$val',
                                style: textStyle.copyWith(
                                  fontSize: 22,
                                  fontWeight: fontWeight,
                                  color: textColor,
                                ),
                              ),
                            ),
                          )
                        : widget.puzzle.notes[r][c].isEmpty
                            ? null
                            : _buildNotes(r, c, textStyle),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
