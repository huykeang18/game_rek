import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rek_piece.dart';
import '../models/move.dart';
import '../logic/rek_rules.dart';
import '../logic/rek_ai.dart';
import '../logic/storage_service.dart';
import '../widgets/piece_selector_bar.dart';
import '../widgets/top_menu_bar.dart';
import '../widgets/bottom_menu_bar.dart';
import '../widgets/wood_board.dart';
import '../widgets/rules_dialog.dart';
import '../widgets/save_load_dialog.dart';
import '../widgets/game_status_overlay.dart';

class RekGameScreen extends StatefulWidget {
  final bool startInPlayMode;
  final bool vsAi;
  final AiDifficulty aiDifficulty;
  final SavedGameState? initialSavedState;

  const RekGameScreen({
    super.key,
    this.startInPlayMode = false,
    this.vsAi = true,
    this.aiDifficulty = AiDifficulty.medium,
    this.initialSavedState,
  });

  @override
  State<RekGameScreen> createState() => _RekGameScreenState();
}

class _RekGameScreenState extends State<RekGameScreen> {
  // Board 8x8
  late List<List<RekPiece?>> _board;

  // Board display rotation
  bool _isRotated = false;

  // Mode: Editor vs Play
  bool _isPlaying = false;

  // Editor State
  PlayerColor _selectedPlayer = PlayerColor.lime;
  PieceType _selectedPieceType = PieceType.plain;
  bool _isEraserActive = false;

  // Play State
  PlayerColor _currentTurn = PlayerColor.lime;
  BoardPosition? _selectedSquare;
  List<BoardPosition> _legalMoves = [];
  List<BoardPosition> _lastMoveFromTo = [];
  List<BoardPosition> _recentCaptures = [];
  final List<RekMove> _moveHistory = [];
  GameOverResult? _gameOverResult;
  String? _lastNotification;

  // AI Opponent
  late bool _vsAi;
  late RekAi _ai;
  bool _isAiThinking = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.startInPlayMode;
    _vsAi = widget.vsAi;
    _ai = RekAi(aiPlayer: PlayerColor.teal, difficulty: widget.aiDifficulty);

    if (widget.initialSavedState != null) {
      _board = RekRules.cloneBoard(widget.initialSavedState!.board);
      _currentTurn = widget.initialSavedState!.currentTurn;
      _isPlaying = widget.initialSavedState!.isPlayMode;
    } else {
      _board = RekRules.createInitialBoard();
    }
  }

  void _resetBoardToStandard() {
    setState(() {
      _board = RekRules.createInitialBoard();
      _selectedSquare = null;
      _legalMoves = [];
      _lastMoveFromTo = [];
      _recentCaptures = [];
      _gameOverResult = null;
      _lastNotification = null;
      _currentTurn = PlayerColor.lime;
      _moveHistory.clear();
    });
  }

  // ---------------------------------------------------------
  // Top Menu Actions
  // ---------------------------------------------------------
  void _onEraseAll() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Clear Board?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Do you want to erase all pieces from the board or reset to standard starting layout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _board = List.generate(
                  RekRules.boardSize,
                  (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
                );
                _selectedSquare = null;
                _legalMoves = [];
              });
            },
            child: const Text('Erase All', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.pop(ctx);
              _resetBoardToStandard();
            },
            child: const Text('Reset Standard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onToggleErase() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEraserActive = !_isEraserActive;
    });
  }

  void _onRotateBoard() {
    HapticFeedback.lightImpact();
    setState(() {
      _isRotated = !_isRotated;
    });
  }

  // ---------------------------------------------------------
  // Bottom Menu Actions
  // ---------------------------------------------------------
  void _onBack() {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (_isPlaying) {
      setState(() => _isPlaying = false);
    } else {
      _showOptionsModal();
    }
  }

  void _onSave() {
    HapticFeedback.lightImpact();
    final currentState = SavedGameState(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Rek Match ${DateTime.now().month}/${DateTime.now().day}',
      timestamp: DateTime.now(),
      board: _board,
      currentTurn: _currentTurn,
      isPlayMode: _isPlaying,
    );

    showDialog(
      context: context,
      builder: (_) => SaveLoadDialog(
        isSaveMode: true,
        currentState: currentState,
        onLoad: _loadSavedGame,
      ),
    );
  }

  void _onLoadGame() {
    HapticFeedback.lightImpact();
    final currentState = SavedGameState(
      id: '',
      name: '',
      timestamp: DateTime.now(),
      board: _board,
      currentTurn: _currentTurn,
      isPlayMode: _isPlaying,
    );

    showDialog(
      context: context,
      builder: (_) => SaveLoadDialog(
        isSaveMode: false,
        currentState: currentState,
        onLoad: _loadSavedGame,
      ),
    );
  }

  void _loadSavedGame(SavedGameState state) {
    setState(() {
      _board = RekRules.cloneBoard(state.board);
      _currentTurn = state.currentTurn;
      _isPlaying = state.isPlayMode;
      _selectedSquare = null;
      _legalMoves = [];
      _lastMoveFromTo = [];
      _recentCaptures = [];
      _gameOverResult = RekRules.checkGameOver(_board, _currentTurn);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded "${state.name}"'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _onPlay() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      _selectedSquare = null;
      _legalMoves = [];
      _isEraserActive = false;
      if (_isPlaying) {
        _gameOverResult = RekRules.checkGameOver(_board, _currentTurn);
      }
    });

    if (_isPlaying && _vsAi && _currentTurn == _ai.aiPlayer && _gameOverResult == null) {
      _triggerAiMove();
    }
  }

  void _onChat() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => RulesDialog(moveHistory: _moveHistory),
    );
  }

  // ---------------------------------------------------------
  // Piece Selectors
  // ---------------------------------------------------------
  void _onSelectPiece(PlayerColor player, PieceType type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPlayer = player;
      _selectedPieceType = type;
      _isEraserActive = false;
    });
  }

  // ---------------------------------------------------------
  // Board Tap Interactions
  // ---------------------------------------------------------
  void _onSquareTap(int row, int col) {
    if (_isPlaying) {
      _handlePlayTap(row, col);
    } else {
      _handleEditorTap(row, col);
    }
  }

  void _handleEditorTap(int row, int col) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isEraserActive) {
        _board[row][col] = null;
      } else {
        _board[row][col] = RekPiece(
          id: '${_selectedPlayer.name}_${DateTime.now().microsecondsSinceEpoch}',
          player: _selectedPlayer,
          type: _selectedPieceType,
        );
      }
    });
  }

  void _handlePlayTap(int row, int col) {
    if (_gameOverResult != null || _isAiThinking) return;

    final targetPos = BoardPosition(row, col);
    final clickedPiece = _board[row][col];

    // 1. If currently have a piece selected and tapped a legal destination
    if (_selectedSquare != null && _legalMoves.contains(targetPos)) {
      _executeMove(_selectedSquare!, targetPos);
      return;
    }

    // 2. Select a friendly piece
    if (clickedPiece != null && clickedPiece.player == _currentTurn) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedSquare = targetPos;
        _legalMoves = RekRules.getLegalMoves(_board, targetPos);
      });
      return;
    }

    // 3. Tapped elsewhere, deselect
    setState(() {
      _selectedSquare = null;
      _legalMoves = [];
    });
  }

  void _executeMove(BoardPosition from, BoardPosition to) {
    HapticFeedback.mediumImpact();
    final move = RekRules.applyMove(_board, from, to);
    _moveHistory.add(move);

    String? notif;
    if (move.rekCaptures.isNotEmpty) {
      notif = '⚡ REK! +${move.rekCaptures.length} captured!';
      HapticFeedback.heavyImpact();
    } else if (move.surroundCaptures.isNotEmpty) {
      notif = '🔒 Trapped +${move.surroundCaptures.length} captured!';
      HapticFeedback.heavyImpact();
    }

    final nextTurn = _currentTurn == PlayerColor.lime ? PlayerColor.teal : PlayerColor.lime;
    final gameOver = RekRules.checkGameOver(_board, nextTurn);

    setState(() {
      _selectedSquare = null;
      _legalMoves = [];
      _lastMoveFromTo = [from, to];
      _recentCaptures = [...move.rekCaptures, ...move.surroundCaptures];
      _lastNotification = notif;
      _currentTurn = nextTurn;
      _gameOverResult = gameOver;
    });

    if (gameOver != null) {
      _showGameOverDialog(gameOver);
    } else if (_vsAi && _currentTurn == _ai.aiPlayer) {
      _triggerAiMove();
    }
  }

  Future<void> _triggerAiMove() async {
    setState(() => _isAiThinking = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted || !_isPlaying || _gameOverResult != null) {
      setState(() => _isAiThinking = false);
      return;
    }

    final bestMove = _ai.selectMove(_board);
    setState(() => _isAiThinking = false);

    if (bestMove != null) {
      _executeMove(bestMove.from, bestMove.to);
    }
  }

  void _showGameOverDialog(GameOverResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD54F), size: 28),
            const SizedBox(width: 8),
            Text(
              '${result.winner.name.toUpperCase()} WINS!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          result.reason,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isPlaying = false);
            },
            child: const Text('Edit Board', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.pop(context);
              _resetBoardToStandard();
              setState(() => _isPlaying = true);
            },
            child: const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF263238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cambodian Rek Game Options',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Play vs AI Opponent', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _vsAi ? 'AI plays Teal (Medium difficulty)' : '2-Player Pass & Play',
                style: const TextStyle(color: Colors.white54),
              ),
              value: _vsAi,
              activeThumbColor: const Color(0xFF00E676),
              onChanged: (val) {
                setState(() => _vsAi = val);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFFFD54F)),
              title: const Text('Return to Home Page', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFFFFD54F)),
              title: const Text('Reset Standard Starting Board', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _resetBoardToStandard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.lightBlueAccent),
              title: const Text('How to Play Rek', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _onChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E272C), // Sleek felt/dark background
      body: SafeArea(
        child: Column(
          children: [
            // Top Menu: Green Wi-Fi, Erase all, Erase, Rotate Baord
            TopMenuBar(
              onEraseAll: _onEraseAll,
              onToggleErase: _onToggleErase,
              isEraserActive: _isEraserActive,
              onRotateBoard: _onRotateBoard,
              isWifiConnected: true,
            ),

            // Top Piece Selectors: Teal Plain & Crown
            PieceSelectorBar(
              player: PlayerColor.teal,
              selectedType: _selectedPlayer == PlayerColor.teal && !_isEraserActive
                  ? _selectedPieceType
                  : null,
              isSelectedPlayer: _selectedPlayer == PlayerColor.teal && !_isEraserActive,
              onSelect: (type) => _onSelectPiece(PlayerColor.teal, type),
            ),

            // Active Game Status / Banner
            GameStatusBanner(
              currentTurn: _currentTurn,
              isPlayMode: _isPlaying,
              lastNotification: _lastNotification,
              gameOverResult: _gameOverResult,
              onReset: _resetBoardToStandard,
              onEdit: () => setState(() => _isPlaying = false),
            ),

            // Main 8x8 Wood Board
            Expanded(
              child: Center(
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

            // Bottom Piece Selectors: Lime Green Plain & Crown (Plain highlighted by default!)
            PieceSelectorBar(
              player: PlayerColor.lime,
              selectedType: _selectedPlayer == PlayerColor.lime && !_isEraserActive
                  ? _selectedPieceType
                  : null,
              isSelectedPlayer: _selectedPlayer == PlayerColor.lime && !_isEraserActive,
              onSelect: (type) => _onSelectPiece(PlayerColor.lime, type),
            ),

            // Bottom Menu: Yellow Back Arrow, Save, Load Game, Play, White Chat Bubble
            BottomMenuBar(
              onBack: _onBack,
              onSave: _onSave,
              onLoadGame: _onLoadGame,
              onPlay: _onPlay,
              onChat: _onChat,
              isPlaying: _isPlaying,
            ),
          ],
        ),
      ),
    );
  }
}
