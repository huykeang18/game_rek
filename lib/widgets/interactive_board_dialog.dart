import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/rek_rules.dart';
import '../models/rek_piece.dart';
import '../services/audio_service.dart';
import '../services/language_service.dart';
import 'wood_board.dart';

class InteractiveBoardDialog extends StatefulWidget {
  final VoidCallback onStartMatch;
  final RekRuleMode initialRuleMode;

  const InteractiveBoardDialog({
    super.key,
    required this.onStartMatch,
    this.initialRuleMode = RekRuleMode.hao,
  });

  @override
  State<InteractiveBoardDialog> createState() => _InteractiveBoardDialogState();
}

class _InteractiveBoardDialogState extends State<InteractiveBoardDialog> {
  late List<List<RekPiece?>> _board;
  late RekRuleMode _ruleMode;
  BoardPosition? _selectedSquare;
  List<BoardPosition> _legalMoves = [];
  List<BoardPosition> _lastMoveFromTo = [];
  List<BoardPosition> _recentCaptures = [];
  bool _isRotated = false;
  PlayerColor _currentTurn = PlayerColor.lime;
  int _moveCount = 0;

  @override
  void initState() {
    super.initState();
    _ruleMode = widget.initialRuleMode;
    _resetBoard();
  }

  void _resetBoard() {
    setState(() {
      _board = RekRules.createInitialBoard();
      _selectedSquare = null;
      _legalMoves = [];
      _lastMoveFromTo = [];
      _recentCaptures = [];
      _currentTurn = PlayerColor.lime;
      _moveCount = 0;
    });
  }

  void _onSquareTap(int row, int col) {
    final pos = BoardPosition(row, col);
    final piece = _board[row][col];

    setState(() {
      if (_selectedSquare == null) {
        if (piece != null && piece.player == _currentTurn) {
          final isHao = RekRules.isHaoActive(_board, _currentTurn, ruleMode: _ruleMode);
          final validMoves = RekRules.getValidMovesForPiece(_board, pos, ruleMode: _ruleMode);
          if (isHao && validMoves.isEmpty) {
            AudioService.instance.playInvalid();
            return;
          }
          _selectedSquare = pos;
          _legalMoves = validMoves;
          AudioService.instance.playClick();
          HapticFeedback.selectionClick();
        }
      } else {
        if (_selectedSquare == pos) {
          // Deselect
          _selectedSquare = null;
          _legalMoves = [];
        } else if (piece != null && piece.player == _board[_selectedSquare!.row][_selectedSquare!.col]?.player) {
          // Switch selection to another piece of the same player
          final isHao = RekRules.isHaoActive(_board, _currentTurn, ruleMode: _ruleMode);
          final validMoves = RekRules.getValidMovesForPiece(_board, pos, ruleMode: _ruleMode);
          if (isHao && validMoves.isEmpty) {
            AudioService.instance.playInvalid();
            return;
          }
          _selectedSquare = pos;
          _legalMoves = validMoves;
          AudioService.instance.playClick();
          HapticFeedback.selectionClick();
        } else if (_legalMoves.contains(pos)) {
          // Execute Move & Apply Captures using standard game rules
          final executedMove = RekRules.applyMove(_board, _selectedSquare!, pos);
          _lastMoveFromTo = [_selectedSquare!, pos];
          _moveCount++;

          final captures = executedMove.allCaptures;
          if (captures.isNotEmpty) {
            _recentCaptures = captures;
            AudioService.instance.playCapture();
            HapticFeedback.mediumImpact();
          } else {
            _recentCaptures = [];
            AudioService.instance.playClick();
            HapticFeedback.lightImpact();
          }

          _currentTurn = _currentTurn == PlayerColor.lime ? PlayerColor.teal : PlayerColor.lime;
          _selectedSquare = null;
          _legalMoves = [];
        } else {
          // Tap on invalid square: deselect
          _selectedSquare = null;
          _legalMoves = [];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final size = MediaQuery.of(context).size;
    final maxBoardWidth = (size.width - 64).clamp(260.0, 440.0);

    return Dialog(
      backgroundColor: const Color(0xFF1B2836),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFD4AF37),
          width: 2.0,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: size.height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.touch_app_outlined,
                      color: Color(0xFFFFD54F),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.interactiveBoardTitle,
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          lang.interactiveBoardSubtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () {
                      AudioService.instance.playClick();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Interactive Turn & Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white12,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentTurn == PlayerColor.lime
                                ? const Color(0xFFA3E635)
                                : const Color(0xFF00F5D4),
                            boxShadow: [
                              BoxShadow(
                                color: (_currentTurn == PlayerColor.lime
                                        ? const Color(0xFFA3E635)
                                        : const Color(0xFF00F5D4))
                                    .withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentTurn == PlayerColor.lime ? 'Lime Turn' : 'Teal Turn',
                          style: TextStyle(
                            color: _currentTurn == PlayerColor.lime
                                ? const Color(0xFFA3E635)
                                : const Color(0xFF00F5D4),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Rule Mode Toggle (Rek vs Hao)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              AudioService.instance.playClick();
                              setState(() {
                                _ruleMode = RekRuleMode.rek;
                                _selectedSquare = null;
                                _legalMoves = [];
                              });
                            },
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _ruleMode == RekRuleMode.rek ? const Color(0xFF2E7D32) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              ),
                              child: Text(
                                'Rek',
                                style: TextStyle(
                                  color: _ruleMode == RekRuleMode.rek ? Colors.white : Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              AudioService.instance.playClick();
                              setState(() {
                                _ruleMode = RekRuleMode.hao;
                                _selectedSquare = null;
                                _legalMoves = [];
                              });
                            },
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _ruleMode == RekRuleMode.hao ? const Color(0xFFE65100) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              ),
                              child: Text(
                                'Call',
                                style: TextStyle(
                                  color: _ruleMode == RekRuleMode.hao ? Colors.white : Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Moves: $_moveCount',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Interactive WoodBoard
              Flexible(
                child: Center(
                  child: SizedBox(
                    width: maxBoardWidth,
                    height: maxBoardWidth,
                    child: WoodBoard(
                      board: _board,
                      isRotated: _isRotated,
                      selectedSquare: _selectedSquare,
                      legalMoves: _legalMoves,
                      lastMoveFromTo: _lastMoveFromTo,
                      recentCaptures: _recentCaptures,
                      onSquareTap: _onSquareTap,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action Buttons Row
              Row(
                children: [
                  // Rotate Board button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFD54F),
                        side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        AudioService.instance.playClick();
                        setState(() => _isRotated = !_isRotated);
                      },
                      icon: const Icon(Icons.rotate_right, size: 18),
                      label: Text(
                        lang.rotateBoard,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Reset Board button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: lang.resetBoardTitle,
                    onPressed: () {
                      AudioService.instance.playClick();
                      _resetBoard();
                    },
                  ),

                  const SizedBox(width: 8),

                  // Start Match button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        AudioService.instance.playClick();
                        Navigator.of(context).pop();
                        widget.onStartMatch();
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(
                        lang.startMatch,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
