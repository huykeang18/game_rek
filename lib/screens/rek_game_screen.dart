import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rek_piece.dart';
import '../models/move.dart';
import '../logic/rek_rules.dart';
import '../logic/rek_ai.dart';
import '../logic/storage_service.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart';
import '../services/language_service.dart';
import '../widgets/piece_selector_bar.dart';
import '../widgets/top_menu_bar.dart';
import '../widgets/bottom_menu_bar.dart';
import '../widgets/wood_board.dart';
import '../widgets/rules_dialog.dart';
import '../widgets/save_load_dialog.dart';
import '../widgets/game_status_overlay.dart';
import '../widgets/profile_edit_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/language_button.dart';
import '../widgets/player_timer_card.dart';

class RekGameScreen extends StatefulWidget {
  final bool startInPlayMode;
  final bool vsAi;
  final AiDifficulty aiDifficulty;
  final int initialTimeLimitSeconds;
  final SavedGameState? initialSavedState;

  const RekGameScreen({
    super.key,
    this.startInPlayMode = false,
    this.vsAi = true,
    this.aiDifficulty = AiDifficulty.medium,
    this.initialTimeLimitSeconds = 300,
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

  // Match Timer for Players
  late int _timeLimitSeconds;
  late int _limeTimeSeconds;
  late int _tealTimeSeconds;
  Timer? _gameTimer;

  // Points & Rewards
  bool _pointsAwarded = false;
  int _earnedPointsThisMatch = 0;

  int get _tealPiecesCount {
    int count = 0;
    for (final row in _board) {
      for (final p in row) {
        if (p != null && p.player == PlayerColor.teal) count++;
      }
    }
    return count;
  }

  int get _limePiecesCount {
    int count = 0;
    for (final row in _board) {
      for (final p in row) {
        if (p != null && p.player == PlayerColor.lime) count++;
      }
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.startInPlayMode;
    _vsAi = widget.vsAi;
    _ai = RekAi(aiPlayer: PlayerColor.teal, difficulty: widget.aiDifficulty);
    _timeLimitSeconds = widget.initialTimeLimitSeconds;
    _limeTimeSeconds = _timeLimitSeconds;
    _tealTimeSeconds = _timeLimitSeconds;

    if (widget.initialSavedState != null) {
      _board = RekRules.cloneBoard(widget.initialSavedState!.board);
      _currentTurn = widget.initialSavedState!.currentTurn;
      _isPlaying = widget.initialSavedState!.isPlayMode;
    } else {
      _board = RekRules.createInitialBoard();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && AudioService.instance.bgmEnabled) {
        AudioService.instance.ensureBgmPlaying();
      }
    });

    if (_isPlaying) {
      AudioService.instance.playGameStart();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    if (!_isPlaying || _gameOverResult != null) return;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isPlaying || _gameOverResult != null) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLimitSeconds > 0) {
          if (_currentTurn == PlayerColor.lime) {
            if (_limeTimeSeconds > 0) {
              _limeTimeSeconds--;
              if (_limeTimeSeconds == 0) {
                _handleTimeout(PlayerColor.lime);
              }
            }
          } else {
            if (_tealTimeSeconds > 0) {
              _tealTimeSeconds--;
              if (_tealTimeSeconds == 0) {
                _handleTimeout(PlayerColor.teal);
              }
            }
          }
        } else {
          // Untimed / Count Up
          if (_currentTurn == PlayerColor.lime) {
            _limeTimeSeconds++;
          } else {
            _tealTimeSeconds++;
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _resetTimer([int? newLimit]) {
    if (newLimit != null) {
      _timeLimitSeconds = newLimit;
    }
    _limeTimeSeconds = _timeLimitSeconds;
    _tealTimeSeconds = _timeLimitSeconds;
    if (_isPlaying && _gameOverResult == null) {
      _startTimer();
    }
  }

  void _processGameWin(GameOverResult result) {
    if (_pointsAwarded) return;
    final isPlayerWinner = result.winner == PlayerColor.lime;
    if (isPlayerWinner) {
      _pointsAwarded = true;
      int points = 100;
      if (_vsAi) {
        switch (widget.aiDifficulty) {
          case AiDifficulty.easy:
            points = 50;
            break;
          case AiDifficulty.medium:
            points = 100;
            break;
          case AiDifficulty.hard:
            points = 200;
            break;
        }
      }
      _earnedPointsThisMatch = points;
      UserService.instance.addWinPoints(points);
    }
  }

  void _handleTimeout(PlayerColor timedOutPlayer) {
    _pauseTimer();
    final winner = timedOutPlayer == PlayerColor.lime ? PlayerColor.teal : PlayerColor.lime;
    final lang = LanguageService.instance;
    final timedOutName = timedOutPlayer == PlayerColor.lime
        ? '${UserService.instance.avatar} ${UserService.instance.username}'
        : (_vsAi ? (lang.isKhmer ? '🤖 AI' : '🤖 Teal AI') : (lang.isKhmer ? '👥 អ្នកលេងទី២' : '👥 Player 2'));
    final winnerName = winner == PlayerColor.lime
        ? '${UserService.instance.avatar} ${UserService.instance.username}'
        : (_vsAi ? (lang.isKhmer ? '🤖 AI' : '🤖 Teal AI') : (lang.isKhmer ? '👥 អ្នកលេងទី២' : '👥 Player 2'));

    final reason = lang.isKhmer
        ? '$timedOutName បានអស់ពេលកំណត់! $winnerName ទទួលបានជ័យជំនះ។'
        : '$timedOutName ran out of time! $winnerName wins the match.';

    final gameOver = GameOverResult(
      winner: winner,
      reason: reason,
    );

    _gameOverResult = gameOver;
    _processGameWin(gameOver);
    final isPlayerWinner = winner == PlayerColor.lime;
    if (isPlayerWinner || !_vsAi) {
      AudioService.instance.playWin();
    } else {
      AudioService.instance.playDefeat();
    }
    _showGameOverDialog(gameOver);
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showTimeControlPicker() {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    final lang = LanguageService.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF263238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFFFD54F), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    lang.timerSettings,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lang.timerSettingsSub,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildTimeControlOption(ctx, 300, lang.timer5Mn, '5 mn'),
              _buildTimeControlOption(ctx, 900, lang.timer15Mn, '15 mn'),
              _buildTimeControlOption(ctx, 1800, lang.timer30Mn, '30 mn'),
              _buildTimeControlOption(ctx, 0, lang.timerUnlimited, '∞'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeControlOption(BuildContext ctx, int seconds, String title, String badge) {
    final isSelected = _timeLimitSeconds == seconds;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          AudioService.instance.playClick();
          Navigator.pop(ctx);
          setState(() {
            _resetTimer(seconds);
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : const Color(0xFF1E272C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF81C784) : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF81C784) : Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF81C784), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _resetBoardToStandard() {
    AudioService.instance.playClear();
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
      _pointsAwarded = false;
      _earnedPointsThisMatch = 0;
      _resetTimer();
    });
  }

  // ---------------------------------------------------------
  // Top Menu Actions
  // ---------------------------------------------------------
  void _onEraseAll() {
    AudioService.instance.playClick();
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
              AudioService.instance.playClear();
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
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    setState(() {
      _isEraserActive = !_isEraserActive;
    });
  }

  void _onRotateBoard() {
    AudioService.instance.playRotate();
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
    AudioService.instance.playClick();
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

    if (_isPlaying) {
      AudioService.instance.playGameStart();
      _startTimer();
    } else {
      _pauseTimer();
    }

    if (_isPlaying && _vsAi && _currentTurn == _ai.aiPlayer && _gameOverResult == null) {
      _triggerAiMove();
    }
  }

  void _onChat() {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF263238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) {
          final lang = LanguageService.instance;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Language Switcher option
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.language, color: Color(0xFF64B5F6)),
                      title: Text(
                        lang.languageSection,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      trailing: const LanguageToggleButton(isCompact: true),
                      onTap: () {
                        AudioService.instance.playClick();
                        LanguageService.instance.toggleLanguage();
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.music_note, color: Color(0xFFFFD54F)),
                      title: Text(lang.musicSettingsTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(lang.musicSettingsSubtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => const SettingsDialog(),
                        );
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.person, color: Color(0xFF81C784)),
                      title: Text(lang.changeProfileTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${UserService.instance.avatar} ${UserService.instance.username}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => const ProfileEditDialog(),
                        );
                      },
                    ),

                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.timer_outlined, color: Color(0xFFFFB74D)),
                      title: Text(lang.timerSettings, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _timeLimitSeconds == 0
                            ? lang.timerUnlimited
                            : '${_timeLimitSeconds ~/ 60} min (${_formatTime(_limeTimeSeconds)} / ${_formatTime(_tealTimeSeconds)})',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showTimeControlPicker();
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.menu_book, color: Color(0xFF4DB6AC)),
                      title: Text(lang.rulesAndHistoryTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(lang.movesPlayed(_moveHistory.length), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => RulesDialog(moveHistory: _moveHistory),
                        );
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.refresh, color: Color(0xFFFF8A65)),
                      title: Text(lang.resetBoardTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(lang.resetBoardSubtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _resetBoardToStandard();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // Piece Selectors
  // ---------------------------------------------------------
  void _onSelectPiece(PlayerColor player, PieceType type) {
    AudioService.instance.playSelect();
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
        if (_board[row][col] != null) {
          AudioService.instance.playErase();
        }
        _board[row][col] = null;
      } else {
        AudioService.instance.playPlace();
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
      AudioService.instance.playSelect();
      HapticFeedback.selectionClick();
      setState(() {
        _selectedSquare = targetPos;
        _legalMoves = RekRules.getLegalMoves(_board, targetPos);
      });
      return;
    }

    // 3. Tapped elsewhere, invalid move or deselect
    if (_selectedSquare != null && !_legalMoves.contains(targetPos)) {
      AudioService.instance.playInvalid();
    }
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
      AudioService.instance.playCapture();
    } else if (move.surroundCaptures.isNotEmpty) {
      notif = '🔒 Trapped +${move.surroundCaptures.length} captured!';
      HapticFeedback.heavyImpact();
      AudioService.instance.playTrap();
    } else {
      AudioService.instance.playMove();
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
      _pauseTimer();
      _processGameWin(gameOver);
      final isPlayerWinner = gameOver.winner == PlayerColor.lime;
      if (isPlayerWinner || !_vsAi) {
        AudioService.instance.playWin();
      } else {
        AudioService.instance.playDefeat();
      }
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
      AudioService.instance.playAiMove();
      _executeMove(bestMove.from, bestMove.to);
    }
  }

  void _showGameOverDialog(GameOverResult result) {
    final lang = LanguageService.instance;
    final isPlayerWinner = result.winner == PlayerColor.lime;
    final winnerName = isPlayerWinner
        ? '${UserService.instance.avatar} ${UserService.instance.username.toUpperCase()}'
        : (_vsAi ? (lang.isKhmer ? '🤖 AI' : '🤖 REK AI') : (lang.isKhmer ? '👥 អ្នកលេងទី២' : '👥 PLAYER 2'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD54F), size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                lang.wins(winnerName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.reason,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (isPlayerWinner && _earnedPointsThisMatch > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFFFD54F), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.pointsEarned(_earnedPointsThisMatch),
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lang.totalPointsTitle}: ${UserService.instance.points} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playClick();
              Navigator.pop(context);
              setState(() => _isPlaying = false);
            },
            child: Text(lang.close, style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              AudioService.instance.playClick();
              Navigator.pop(context);
              _resetBoardToStandard();
              setState(() => _isPlaying = true);
            },
            child: Text(lang.playAgain, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOptionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF263238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
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
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;

        return Scaffold(
          backgroundColor: const Color(0xFF1E272C),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > constraints.maxHeight * 1.15;
                if (isLandscape) {
                  return _buildLandscapeLayout(context, constraints, lang);
                } else {
                  return _buildPortraitLayout(context, constraints, lang);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, BoxConstraints constraints, LanguageService lang) {
    final screenHeight = constraints.maxHeight;
    final isCompactHeight = screenHeight < 680;
    final tokenSize = isCompactHeight ? 34.0 : 40.0;

    return Column(
      children: [
        // Top Menu: Green Wi-Fi, Erase all (if editor), Erase (if editor), Rotate Baord
        TopMenuBar(
          onEraseAll: _onEraseAll,
          onToggleErase: _onToggleErase,
          isEraserActive: _isEraserActive,
          onRotateBoard: _onRotateBoard,
          isWifiConnected: true,
          labelEraseAll: lang.eraseAll,
          labelErase: lang.erase,
          labelRotateBoard: lang.rotateBoard,
          showEditorButtons: !_isPlaying,
        ),

        // TOP: PlayerTimerCard in play mode, PieceSelectorBar in editor mode
        if (_isPlaying)
          PlayerTimerCard(
            player: PlayerColor.teal,
            name: _vsAi ? 'Teal AI (${widget.aiDifficulty.name})' : (lang.isKhmer ? 'អ្នកលេងទី២' : 'Player 2 (Teal)'),
            avatar: _vsAi ? '🤖' : '👤',
            piecesCount: _tealPiecesCount,
            timeSeconds: _tealTimeSeconds,
            isTurn: _currentTurn == PlayerColor.teal,
            isAi: _vsAi,
            isUntimed: _timeLimitSeconds == 0,
            onTimerTap: _showTimeControlPicker,
          )
        else
          PieceSelectorBar(
            player: PlayerColor.teal,
            selectedType: _selectedPlayer == PlayerColor.teal && !_isEraserActive
                ? _selectedPieceType
                : null,
            isSelectedPlayer: _selectedPlayer == PlayerColor.teal && !_isEraserActive,
            onSelect: (type) => _onSelectPiece(PlayerColor.teal, type),
            tokenSize: tokenSize,
          ),

        // Active Game Status / Banner
        ListenableBuilder(
          listenable: UserService.instance,
          builder: (context, _) => GameStatusBanner(
            currentTurn: _currentTurn,
            isPlayMode: _isPlaying,
            lastNotification: _lastNotification,
            gameOverResult: _gameOverResult,
            onReset: _resetBoardToStandard,
            onEdit: () => setState(() => _isPlaying = false),
            playerName: UserService.instance.username,
            playerAvatar: UserService.instance.avatar,
            vsAi: _vsAi,
          ),
        ),

        // Main 8x8 Wood Board (constrained to never overflow on tablets or desktop)
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
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

        // BOTTOM: PlayerTimerCard in play mode, PieceSelectorBar in editor mode
        if (_isPlaying)
          ListenableBuilder(
            listenable: UserService.instance,
            builder: (context, _) => PlayerTimerCard(
              player: PlayerColor.lime,
              name: UserService.instance.username,
              avatar: UserService.instance.avatar,
              piecesCount: _limePiecesCount,
              timeSeconds: _limeTimeSeconds,
              isTurn: _currentTurn == PlayerColor.lime,
              isUntimed: _timeLimitSeconds == 0,
              onTimerTap: _showTimeControlPicker,
            ),
          )
        else
          PieceSelectorBar(
            player: PlayerColor.lime,
            selectedType: _selectedPlayer == PlayerColor.lime && !_isEraserActive
                ? _selectedPieceType
                : null,
            isSelectedPlayer: _selectedPlayer == PlayerColor.lime && !_isEraserActive,
            onSelect: (type) => _onSelectPiece(PlayerColor.lime, type),
            tokenSize: tokenSize,
          ),

        // Bottom Menu: Yellow Back Arrow, Save (only in editor mode), Play, White Chat Bubble
        BottomMenuBar(
          onBack: _onBack,
          onSave: _onSave,
          onPlay: _onPlay,
          onChat: _onChat,
          isPlaying: _isPlaying,
          labelSave: lang.save,
          labelPlay: lang.play,
          showSave: !_isPlaying,
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, BoxConstraints constraints, LanguageService lang) {
    return Column(
      children: [
        // Unified Header for Landscape Mode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            border: const Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              // Yellow back arrow
              InkWell(
                onTap: _onBack,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back, color: Color(0xFFFFD54F), size: 22),
                ),
              ),
              const SizedBox(width: 8),
              // Green Wi-Fi icon
              const Icon(Icons.wifi, color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 10),
              // Status banner in landscape top bar
              Expanded(
                child: ListenableBuilder(
                  listenable: UserService.instance,
                  builder: (context, _) => GameStatusBanner(
                    currentTurn: _currentTurn,
                    isPlayMode: _isPlaying,
                    lastNotification: _lastNotification,
                    gameOverResult: _gameOverResult,
                    onReset: _resetBoardToStandard,
                    onEdit: () => setState(() => _isPlaying = false),
                    playerName: UserService.instance.username,
                    playerAvatar: UserService.instance.avatar,
                    vsAi: _vsAi,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Menu Actions (Erase all, Erase, and Save hidden during play mode)
              if (!_isPlaying) ...[
                _buildCompactBtn(lang.eraseAll, _onEraseAll, isDestructive: true),
                const SizedBox(width: 6),
                _buildCompactBtn(lang.erase, _onToggleErase, isActive: _isEraserActive),
                const SizedBox(width: 6),
              ],
              _buildCompactBtn(lang.rotateBoard, _onRotateBoard),
              if (!_isPlaying) ...[
                const SizedBox(width: 6),
                _buildCompactBtn(lang.save, _onSave),
              ],
              const SizedBox(width: 6),
              _buildCompactBtn(
                lang.play,
                _onPlay,
                highlight: true,
                backgroundColor: _isPlaying ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              // White Chat Bubble
              InkWell(
                onTap: _onChat,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chat_bubble, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),

        // Main Row: Left selectors / Timers, Center board, Right move log
        Expanded(
          child: Row(
            children: [
              // Left Panel: Timers in play mode, Piece Selectors in editor mode
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: SingleChildScrollView(
                  child: _isPlaying
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PlayerTimerCard(
                              player: PlayerColor.teal,
                              name: _vsAi ? 'Teal AI' : (lang.isKhmer ? 'អ្នកលេងទី២' : 'Player 2'),
                              avatar: _vsAi ? '🤖' : '👤',
                              piecesCount: _tealPiecesCount,
                              timeSeconds: _tealTimeSeconds,
                              isTurn: _currentTurn == PlayerColor.teal,
                              isAi: _vsAi,
                              isUntimed: _timeLimitSeconds == 0,
                              onTimerTap: _showTimeControlPicker,
                              isCompact: true,
                            ),
                            const SizedBox(height: 10),
                            ListenableBuilder(
                              listenable: UserService.instance,
                              builder: (context, _) => PlayerTimerCard(
                                player: PlayerColor.lime,
                                name: UserService.instance.username,
                                avatar: UserService.instance.avatar,
                                piecesCount: _limePiecesCount,
                                timeSeconds: _limeTimeSeconds,
                                isTurn: _currentTurn == PlayerColor.lime,
                                isUntimed: _timeLimitSeconds == 0,
                                onTimerTap: _showTimeControlPicker,
                                isCompact: true,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'TEAL',
                              style: TextStyle(
                                color: Color(0xFF80CBC4),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            PieceSelectorBar(
                              player: PlayerColor.teal,
                              selectedType: _selectedPlayer == PlayerColor.teal && !_isEraserActive
                                  ? _selectedPieceType
                                  : null,
                              isSelectedPlayer: _selectedPlayer == PlayerColor.teal && !_isEraserActive,
                              onSelect: (type) => _onSelectPiece(PlayerColor.teal, type),
                              isVertical: false,
                              tokenSize: 32,
                            ),
                            const Divider(color: Colors.white12, height: 16),
                            const Text(
                              'LIME GREEN',
                              style: TextStyle(
                                color: Color(0xFFC5E1A5),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            PieceSelectorBar(
                              player: PlayerColor.lime,
                              selectedType: _selectedPlayer == PlayerColor.lime && !_isEraserActive
                                  ? _selectedPieceType
                                  : null,
                              isSelectedPlayer: _selectedPlayer == PlayerColor.lime && !_isEraserActive,
                              onSelect: (type) => _onSelectPiece(PlayerColor.lime, type),
                              isVertical: false,
                              tokenSize: 32,
                            ),
                          ],
                        ),
                ),
              ),

              // Center: 8x8 Wood Board
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: AspectRatio(
                      aspectRatio: 1.0,
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
              ),

              // Right Panel: Move Log summary
              Container(
                width: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  border: const Border(left: BorderSide(color: Colors.white10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MOVE LOG',
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${_moveHistory.length}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 10),
                    Expanded(
                      child: _moveHistory.isEmpty
                          ? const Center(
                              child: Text(
                                'Tap "Play" to start',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _moveHistory.length,
                              itemBuilder: (ctx, i) {
                                final move = _moveHistory[_moveHistory.length - 1 - i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${_moveHistory.length - i}. ${move.description}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBtn(
    String label,
    VoidCallback onTap, {
    bool isActive = false,
    bool isDestructive = false,
    bool highlight = false,
    Color? backgroundColor,
  }) {
    final bg = backgroundColor ??
        (isActive
            ? const Color(0xFFE57373)
            : const Color(0xFF2C3E50).withValues(alpha: 0.85));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: highlight
                  ? const Color(0xFF81C784)
                  : Colors.white.withValues(alpha: 0.25),
              width: highlight ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDestructive && !isActive ? const Color(0xFFFFCDD2) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
