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
  final VoidCallback? onRequestInput;

  const SudokuBoard({
    super.key,
    required this.puzzle,
    this.noteMode = false,
    this.readOnly = false,
    this.onCellChanged,
    this.onRefresh,
    this.onRequestInput,
  });

  @override
  State<SudokuBoard> createState() => SudokuBoardState();
}

class SudokuBoardState extends State<SudokuBoard> {
  int? _selectedRow, _selectedCol;
  final Set<String> _errors = {};

  int get _gs => widget.puzzle.gridSize;
  int get _bs => widget.puzzle.boardSize;

  /// 清除当前选中格（供物理键盘 Backspace/Delete 调用）
  void clearSelected() {
    if (_selectedRow == null || _selectedCol == null || widget.readOnly) return;
    final r = _selectedRow!, c = _selectedCol!;
    if (widget.puzzle.given[r][c]) return;
    final old = widget.puzzle.cells[r][c];
    if (old == 0 && widget.puzzle.notes[r][c].isEmpty) return;
    setState(() {
      widget.puzzle.cells[r][c] = 0;
      widget.puzzle.notes[r][c].clear();
      _errors.remove('$r,$c');
    });
    if (old != 0) widget.onCellChanged?.call(r, c, old, 0);
    widget.onRefresh?.call();
  }

  void fillNumber(int n) {
    if (_selectedRow == null || _selectedCol == null || widget.readOnly) return;
    final r = _selectedRow!, c = _selectedCol!;
    if (widget.puzzle.given[r][c]) return;

    if (widget.noteMode) {
      if (widget.puzzle.notes[r][c].contains(n)) {
        setState(() => widget.puzzle.notes[r][c].remove(n));
      } else {
        setState(() => widget.puzzle.setNote(r, c, n));
      }
    } else {
      final old = widget.puzzle.cells[r][c];
      setState(() {
        widget.puzzle.cells[r][c] = n;
        widget.puzzle.notes[r][c].clear();
        _errors.remove('$r,$c');
        if (n != widget.puzzle.solution[r][c]) _errors.add('$r,$c');
      });
      widget.onCellChanged?.call(r, c, old, n);
    }
    widget.onRefresh?.call();
  }

  void _onCellTap(int r, int c) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
    if (!widget.readOnly) {
      widget.onRequestInput?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.montserrat();
    final fontSize = _gs == 9 ? 22.0 : 14.0;
    final noteSize = _gs == 9 ? 13.0 : 9.0;

    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF455A64), width: 2.5),
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.hardEdge,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _gs * _gs,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gs, mainAxisSpacing: 0, crossAxisSpacing: 0,
          ),
          itemBuilder: (_, index) {
            final r = index ~/ _gs, c = index % _gs;
            final val = widget.puzzle.cells[r][c];
            final isGiven = widget.puzzle.given[r][c];
            final isSelected = _selectedRow == r && _selectedCol == c;
            final isError = _errors.contains('$r,$c');
            final inSameRow = _selectedRow == r;
            final inSameCol = _selectedCol == c;
            final inSameBox = _selectedRow != null && _selectedCol != null &&
                r ~/ _bs == _selectedRow! ~/ _bs && c ~/ _bs == _selectedCol! ~/ _bs;
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

            final display = val != 0 ? SudokuPuzzle.displayValue(val) : '';

            return GestureDetector(
              onTap: () => _onCellTap(r, c),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFBBDEFB)
                       : isHighlighted ? const Color(0xFFF0F4F8)
                       : Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: (c + 1) % _bs == 0 ? const Color(0xFF455A64) : Colors.grey[300]!,
                      width: (c + 1) % _bs == 0 ? 2 : 0.5,
                    ),
                    bottom: BorderSide(
                      color: (r + 1) % _bs == 0 ? const Color(0xFF455A64) : Colors.grey[300]!,
                      width: (r + 1) % _bs == 0 ? 2 : 0.5,
                    ),
                  ),
                ),
                child: val != 0
                    ? Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            display,
                            style: textStyle.copyWith(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: textColor,
                            ),
                          ),
                        ),
                      )
                    : widget.puzzle.notes[r][c].isEmpty
                        ? null
                        : _buildNotes(r, c, textStyle, noteSize),
              ),
            );
          },
        ),
    );
  }

  Widget _buildNotes(int r, int c, TextStyle ts, double fontSize) {
    if (widget.puzzle.notes[r][c].isEmpty) return const SizedBox.shrink();
    final n = widget.puzzle.notes[r][c].first;
    return Padding(
      padding: EdgeInsets.all(_gs == 9 ? 3 : 2),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          n <= 9 ? '$n' : String.fromCharCode(0x41 + n - 10),
          style: ts.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0B4CFF),
          ),
        ),
      ),
    );
  }
}
